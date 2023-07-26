#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：chmod +x install.sh && ./install.sh
# 仓库：https://jihulab.com/xuxiaowei-com-cn/k8s.sh
#

while getopts "vm" opt; do
  case $opt in
  v)
    # 用于创建 VIP

    AVAILABILITY=true
    echo "选项 -v 被激活"
    ;;
  m)
    # 用于使用 VIP 创建主节点

    AVAILABILITY_MASTER=true
    if ! [ "$AVAILABILITY_VIP" ]; then
      echo "高可用 VIP 不存在，停止安装。请设置环境变量 AVAILABILITY_VIP"
      exit 1
    fi
    echo "选项 -m 被激活"
    ;;
  \?)
    echo "无效的选项: -$OPTARG"
    ;;
  esac
done

# 系统判断
function osName() {
  if grep -q "CentOS" /etc/os-release; then
    echo "当前系统是 CentOS"
    osVersion
  elif grep -q "Anolis" /etc/os-release; then
    echo "系统是 Anolis"
    osVersion
  else
    echo "系统不是 CentOS 或 Anolis，不支持，停止安装"
    exit 1
  fi
}

# 系统版本判断
function osVersion() {
  # 导入操作系统信息
  . /etc/os-release

  if [[ $VERSION_ID == 7* ]]; then
    echo "$VERSION_ID"
    OS_VERSION=7
  elif [[ $VERSION_ID == 8* ]]; then
    echo "$VERSION_ID"
    OS_VERSION=8
  elif [[ $VERSION_ID == 23* ]]; then
    # 兼容 Anolis 23
    echo "$VERSION_ID"
    OS_VERSION=23
  else
    echo "$VERSION_ID：不支持的操作系统版本，停止安装"
    exit 1
  fi
}

# VIP 网卡选择
function availabilityInterfaceName() {
  sudo yum -y install iproute
  if ip link show "$AVAILABILITY_INTERFACE_NAME" >/dev/null 2>&1; then
    echo "VIP 网卡 $AVAILABILITY_INTERFACE_NAME 存在"
  else
    echo "VIP 网卡 $AVAILABILITY_INTERFACE_NAME 不存在，停止安装。请重新定义变量 AVAILABILITY_INTERFACE_NAME 选择 VIP 网卡，命令示例：export AVAILABILITY_INTERFACE_NAME=VIP要使用的网卡名称"
    exit 1
  fi
}

function availabilityMaster() {

  if ! [ "$AVAILABILITY_VIP" ]; then
    echo "高可用 VIP 不存在，停止安装。请设置环境变量 AVAILABILITY_VIP"
    exit 1
  fi

  if ! [ "$AVAILABILITY_INTERFACE_NAME" ]; then
    echo "高可用 网卡名称 不存在，停止安装。请设置环境变量 AVAILABILITY_INTERFACE_NAME"
    exit 1
  fi

  if ! [ "$AVAILABILITY_MASTER" ]; then
    echo "k8s 主节点信息 不存在，停止安装。请设置环境变量 AVAILABILITY_MASTER"
    exit 1
  fi

  AVAILABILITY_MASTER_ARRAY=()

  # 解析环境变量的值
  IFS=',' read -ra masters <<<"$AVAILABILITY_MASTER"
  for master in "${masters[@]}"; do
    IFS='@' read -ra parts <<<"$master"
    name="${parts[0]}"
    address="${parts[1]}"

    echo "名称: $name"
    echo "地址: $address"

    # 将解析结果存入数组
    AVAILABILITY_MASTER_ARRAY+=("$name $address")
  done

  if ! [ "$AVAILABILITY_VIP_NO" ]; then
    echo "VIP 编号 不存在，停止安装。请设置环境变量 AVAILABILITY_VIP_NO"
    exit 1
  fi

  # 验证 AVAILABILITY_VIP_NO 是否为整数
  if ! [[ "$AVAILABILITY_VIP_NO" =~ ^[0-9]+$ ]]; then
    echo "VIP 编号 AVAILABILITY_VIP_NO 必须是整数，停止安装。请重新设置环境变量 AVAILABILITY_VIP_NO"
    exit 1
  fi

  # 验证 AVAILABILITY_VIP_NO 是否大于 0
  if ((AVAILABILITY_VIP_NO <= 0)); then
    echo "VIP 编号 AVAILABILITY_VIP_NO 必须大于 0，停止安装。请重新设置环境变量 AVAILABILITY_VIP_NO"
    exit 1
  fi

  if [ "$AVAILABILITY_VIP_NO" == 1 ]; then
    AVAILABILITY_VIP_STATE=MASTER
  else
    AVAILABILITY_VIP_STATE=BACKUP
  fi

}

# VIP haproxy
function availabilityHaproxy() {
  if ! [ "$AVAILABILITY_HAPROXY_USERNAME" ]; then
    AVAILABILITY_HAPROXY_USERNAME=admin
  fi
  if ! [ "$AVAILABILITY_HAPROXY_PASSWORD" ]; then
    AVAILABILITY_HAPROXY_PASSWORD=password
  fi

  mkdir -p /etc/kubernetes/

  cat >/etc/kubernetes/haproxy.cfg <<EOF
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4096
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  forwardfor    except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend  kube-apiserver
    mode                 tcp
    bind                 *:9443
    option               tcplog
    default_backend      kube-apiserver

listen stats
    mode                 http
    bind                 *:8888
    stats auth           $AVAILABILITY_HAPROXY_USERNAME:$AVAILABILITY_HAPROXY_PASSWORD
    stats refresh        5s
    stats realm          HAProxy\ Statistics
    stats uri            /stats
    log                  127.0.0.1 local3 err

backend kube-apiserver
    mode        tcp
    balance     roundrobin
EOF

  cat /etc/kubernetes/haproxy.cfg

  # 遍历数组
  for master in "${AVAILABILITY_MASTER_ARRAY[@]}"; do
    echo "    server  $master check" >>/etc/kubernetes/haproxy.cfg
  done

  echo "" >>/etc/kubernetes/haproxy.cfg

  cat /etc/kubernetes/haproxy.cfg

  docker run \
    -d \
    --name k8s-haproxy \
    --net=host \
    --restart=always \
    -v /etc/kubernetes/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
    haproxytech/haproxy-debian:2.8

}

# VIP keepalived
function availabilityKeepalived() {

  mkdir -p /etc/kubernetes/

  cat >/etc/kubernetes/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   router_id LVS_$AVAILABILITY_VIP_NO
}

vrrp_script checkhaproxy
{
    script "/usr/bin/check-haproxy.sh"
    interval 2
    weight -30
}

vrrp_instance VI_1 {
    state $AVAILABILITY_VIP_STATE
    interface $AVAILABILITY_INTERFACE_NAME
    virtual_router_id 51
    priority 100
    advert_int 1

    virtual_ipaddress {
        $AVAILABILITY_VIP/24 dev $AVAILABILITY_INTERFACE_NAME
    }

    authentication {
        auth_type PASS
        auth_pass password
    }

    track_script {
        checkhaproxy
    }
}

EOF

  cat >/etc/kubernetes/check-haproxy.sh <<EOF
#!/bin/bash

count=\`netstat -apn | grep 9443 | wc -l\`

if [ $count -gt 0 ]; then
    exit 0
else
    exit 1
fi

EOF

  cat /etc/kubernetes/keepalived.conf
  cat /etc/kubernetes/check-haproxy.sh

  docker run \
    -d \
    --name k8s-keepalived \
    --restart=always \
    --net=host \
    --cap-add=NET_ADMIN \
    --cap-add=NET_BROADCAST \
    --cap-add=NET_RAW \
    -v /etc/kubernetes/keepalived.conf:/container/service/keepalived/assets/keepalived.conf \
    -v /etc/kubernetes/check-haproxy.sh:/usr/bin/check-haproxy.sh \
    lettore/keepalived:3.16-2.2.7 \
    --copy-service

}

# VIP
function availabilityVip() {
  if [ "$AVAILABILITY" == true ]; then
    echo "开始创建 VIP"

    availabilityMaster

    availabilityInterfaceName

    dockerInstall

    availabilityHaproxy

    availabilityKeepalived

    echo ""
    echo ""
    echo ""
    echo "VIP 创建完成，退出程序。"
    echo "访问本机IP，端口 8888，路径 /stats，用户名密码个人未指定时是 admin/password"
    echo ""
    echo ""
    echo ""
    exit 0
  fi

}

# k8s集群模式
function installMode() {
  if [ "$INSTALL_MODE" ]; then
    if ! [[ "$INSTALL_MODE" =~ ^(standalone|master|node)$ ]]; then
      echo "k8s集群模式：$INSTALL_MODE，不合法，停止安装"
      exit 1
    fi
  else
    INSTALL_MODE=standalone
  fi

  echo "k8s集群模式：$INSTALL_MODE"
}

# k8s 版本
function k8sVersion() {
  if [ "$KUBERNETES_VERSION" ]; then
    if [[ $KUBERNETES_VERSION =~ ^[0-9.]+$ ]]; then
      echo "指定 k8s 版本：$KUBERNETES_VERSION"
    else
      echo "不支持 k8s 版本：$KUBERNETES_VERSION，停止安装（版本号只能包含：数字、小数点）"
      exit 1
    fi
  else
    echo "未指定 k8s 版本，安装最新版 k8s"
  fi
}

# 主机名判断
function hostName() {
  ETC_HOSTNAME=$(cat /etc/hostname)
  CMD_HOSTNAME=$(hostname)
  if [[ $CMD_HOSTNAME =~ ^[A-Za-z0-9\.\-]+$ ]]; then
    if [ "$ETC_HOSTNAME" == "$CMD_HOSTNAME" ]; then
      echo "主机名符合要求"
    else
      echo "临时主机名：$CMD_HOSTNAME"
      echo "配置文件主机名：$ETC_HOSTNAME"
      echo "临时主机名符合要求，但是配置文件与临时主机名不同，系统重启后，将使用配置文件主机名，可能造成 k8s 无法正常运行。"
      echo "由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请将配置文件 /etc/hostname 中的主机名与命令 hostname 修改成一致的名称。"
      echo "hostname 是临时主机名，重启后使用 /etc/hostname 文件中的内容作为主机名。"
      exit 1
    fi
  else
    echo "主机名不符合要求，只能包含：字母、数字、小数点、英文横杠。"
    echo "由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请自行修改。"
    exit 1
  fi
}

# 网卡选择
function interfaceName() {

  sudo yum -y install iproute

  if [ "$INTERFACE_NAME" ]; then
    echo "选择的上网网卡是：$INTERFACE_NAME"

    if ip link show "$INTERFACE_NAME" >/dev/null 2>&1; then
      echo "网卡 $INTERFACE_NAME 存在"
    else
      echo "网卡 $INTERFACE_NAME 不存在，停止安装。请重新定义变量 INTERFACE_NAME 选择网卡，命令示例：export INTERFACE_NAME=要使用的网卡名称"
      exit 1
    fi
  else
    INTERFACE_NAME=$(ip route get 223.5.5.5 | grep -oP '(?<=dev\s)\w+' | head -n 1)
    if [ "$INTERFACE_NAME" ]; then
      echo "上网网卡是：$INTERFACE_NAME"
    else
      echo "未找到上网网卡，停止安装"
      exit 1
    fi
  fi
}

# 安装、配置 NTP（网络时间协议）
function ntpdateInstall() {
  if [ $OS_VERSION == 7 ]; then
    sudo yum -y install ntpdate
    sudo ntpdate ntp1.aliyun.com
    sudo systemctl status ntpdate
    sudo systemctl start ntpdate
    sudo systemctl status ntpdate
    sudo systemctl enable ntpdate
  elif [ $OS_VERSION == 8 ] || [ $OS_VERSION == 23 ]; then
    # 兼容 Anolis 23
    sudo yum -y install chrony
    sudo systemctl status chronyd -n 0
    sudo systemctl start chronyd
    sudo systemctl status chronyd -n 0
    sudo systemctl enable chronyd
  fi
}

# bash-completion 安装、配置
function bashCompletionInstall() {
  sudo yum -y install bash-completion
  source /etc/profile
}

# 停止防火墙
function stopFirewalld() {
  sudo systemctl stop firewalld.service
  sudo systemctl disable firewalld.service
}

# 关闭交换空间
function swapOff() {
  free -h
  sudo swapoff -a
  sudo sed -i 's/.*swap.*/#&/' /etc/fstab
  free -h
}

# 关闭 selinux
function selinuxPermissive() {
  getenforce
  cat /etc/selinux/config
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  cat /etc/selinux/config
}

# 安装、配置 Docker、containerd
function dockerInstall() {
  # https://docs.docker.com/engine/install/centos/
  # 经过测试，可不安装 docker 也可使 k8s 正常运行：只需要不安装 docker-ce、docker-ce-cli、docker-compose-plugin 即可

  # 卸载旧 docker
  sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

  # 安装 docker 仓库
  sudo yum install -y curl
  sudo curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo

  # 兼容 Anolis 23
  if [ "$OS_VERSION" == 23 ]; then
    sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
  fi

  # 搜索 docker 版本
  # yum --showduplicates list docker-ce

  # 安装 docker
  sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # 启动 docker 时，会启动 containerd
  # sudo systemctl status containerd.service -n 0
  sudo systemctl stop containerd.service

  sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
  containerd config default >~/config.toml
  sudo cp ~/config.toml /etc/containerd/config.toml
  # 修改 /etc/containerd/config.toml 文件后，要将 docker、containerd 停止后，再启动
  sudo sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml
  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd
  # 确保 /etc/containerd/config.toml 中的 disabled_plugins 内不存在 cri
  sudo sed -i "s#SystemdCgroup = false#SystemdCgroup = true#g" /etc/containerd/config.toml

  # containerd 忽略证书验证的配置
  #      [plugins."io.containerd.grpc.v1.cri".registry.configs]
  #        [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.0.12:8001".tls]
  #          insecure_skip_verify = true

  sudo systemctl enable --now containerd.service
  # sudo systemctl status containerd.service -n 0

  # sudo systemctl status docker.service -n 0
  sudo systemctl start docker.service
  # sudo systemctl status docker.service -n 0
  sudo systemctl enable docker.service
  sudo systemctl enable docker.socket
  sudo systemctl list-unit-files | grep docker

  sudo mkdir -p /etc/docker

  sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hnkfbj7x.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo docker info

  sudo systemctl status docker.service -n 0
  sudo systemctl status containerd.service -n 0
}

# 阿里云 kubernetes 仓库
function aliyunKubernetesRepo() {
  cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
# 是否开启本仓库
enabled=1
# 是否检查 gpg 签名文件
gpgcheck=0
# 是否检查 gpg 签名文件
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF
}

# k8s 配置
function k8sConf() {
  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  sudo modprobe overlay
  sudo modprobe br_netfilter

  # 设置所需的 sysctl 参数，参数在重新启动后保持不变
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  # 应用 sysctl 参数而不重新启动
  sudo sysctl --system

  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
  # 通过运行以下指令确认 br_netfilter 和 overlay 模块被加载：
  lsmod | grep br_netfilter
  lsmod | grep overlay

  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
  # 通过运行以下指令确认 net.bridge.bridge-nf-call-iptables、net.bridge.bridge-nf-call-ip6tables 和 net.ipv4.ip_forward 系统变量在你的 sysctl 配置中被设置为 1：
  sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
}

# k8s 安装
function k8sInstall() {
  if [ "$KUBERNETES_VERSION" ]; then
    sudo yum install -y kubelet-"$KUBERNETES_VERSION"-0 kubeadm-"$KUBERNETES_VERSION"-0 kubectl-"$KUBERNETES_VERSION"-0 --disableexcludes=kubernetes --nogpgcheck
  else
    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
  fi
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl enable kubelet
}

function imagesPull() {
  if [ "$IMAGES_PULL" ]; then
    if [ "$KUBERNETES_VERSION" ]; then
      kubeadm config images list --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$KUBERNETES_VERSION"
      kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$KUBERNETES_VERSION"
    else
      kubeadm config images list --image-repository=registry.aliyuncs.com/google_containers
      kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers
    fi
  fi
}

# k8s 初始化
function k8sInit() {
  if [ "$AVAILABILITY_MASTER" ]; then
    if [ "$KUBERNETES_VERSION" ]; then
      kubeadm init --image-repository=registry.aliyuncs.com/google_containers --control-plane-endpoint "$AVAILABILITY_VIP:9443" --upload-certs --kubernetes-version=v"$KUBERNETES_VERSION"
    else
      kubeadm init --image-repository=registry.aliyuncs.com/google_containers --control-plane-endpoint "$AVAILABILITY_VIP:9443" --upload-certs
    fi
  else
    if [ "$KUBERNETES_VERSION" ]; then
      kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$KUBERNETES_VERSION"
    else
      kubeadm init --image-repository=registry.aliyuncs.com/google_containers
    fi
  fi

  echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >>/etc/profile
  source /etc/profile
  source <(kubectl completion bash)
  echo "source <(kubectl completion bash)" >>~/.bashrc
  kubectl cluster-info
  kubectl get nodes
  kubectl get pod,svc --all-namespaces -o wide
}

# calico 网络插件 安装
function calicoInstall() {
  if [ "$CALICO_VERSION" ]; then
    curl -o calico.yaml https://docs.tigera.io/archive/v"$CALICO_VERSION"/manifests/calico.yaml
  else
    curl -o calico.yaml https://docs.tigera.io/archive/v3.25/manifests/calico.yaml
  fi

  sed -i '/k8s,bgp/a \            - name: IP_AUTODETECTION_METHOD\n              value: "interface=INTERFACE_NAME"' calico.yaml
  sed -i "s#INTERFACE_NAME#$INTERFACE_NAME#g" calico.yaml

  if [ "$CALICO_MIRRORS_CALICO_CNI" ]; then
    echo "接收到环境变量中的参数 CALICO_MIRRORS_CALICO_CNI：$CALICO_MIRRORS_CALICO_CNI"
    sed -i "s#docker\.io#$CALICO_MIRRORS_CALICO_CNI#g" calico.yaml
  fi

  if [ "$CALICO_MIRRORS_KUBE_CONTROLLERS" ]; then
    echo "接收到环境变量中的参数 CALICO_MIRRORS_KUBE_CONTROLLERS：$CALICO_MIRRORS_KUBE_CONTROLLERS"
    sed -i "s#docker\.io#$CALICO_MIRRORS_KUBE_CONTROLLERS#g" calico.yaml
  fi

  if [ "$CALICO_MIRRORS_CALICO_NODE" ]; then
    echo "接收到环境变量中的参数 CALICO_MIRRORS_CALICO_NODE：$CALICO_MIRRORS_CALICO_NODE"
    sed -i "s#docker\.io#$CALICO_MIRRORS_CALICO_NODE#g" calico.yaml
  fi

  if [ "$CALICO_MIRRORS" ]; then
    echo "接收到环境变量中的参数 CALICO_MIRRORS：$CALICO_MIRRORS"
    sed -i "s#docker\.io#$CALICO_MIRRORS#g" calico.yaml
  fi

  kubectl apply -f calico.yaml
  kubectl get nodes
  kubectl get pod,svc --all-namespaces -o wide
}

# Metrics Server 插件
function metricsServerInstall() {
  if [ "$METRICS_SERVER_INSTALL" == true ]; then
    echo "启用 Metrics Server 插件 安装"

    # 自定义镜像：优先级高于 METRICS_SERVER_VERSION、METRICS_SERVER_AVAILABILITY
    if [ "$METRICS_SERVER_MIRROR" ]; then
      curl -o components.yaml "$METRICS_SERVER_MIRROR"
    else

      # 自定义版本
      if ! [ "$METRICS_SERVER_VERSION" ]; then
        METRICS_SERVER_VERSION=0.6.3
      fi

      # 自定义高可用
      if [ "$METRICS_SERVER_AVAILABILITY" == true ]; then
        curl -o components.yaml "https://github.com/kubernetes-sigs/metrics-server/releases/download/v$METRICS_SERVER_VERSION/high-availability-1.21+.yaml"
      else
        curl -o components.yaml "https://github.com/kubernetes-sigs/metrics-server/releases/download/v$METRICS_SERVER_VERSION/components.yaml"
      fi

    fi

    # 不验证证书
    sed -i '/- args:/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

    # 使用 docker hub 镜像
    sed -i 's|registry\.k8s\.io/metrics-server/metrics-server|docker.io/xuxiaoweicomcn/metrics-server|g' components.yaml

    # 应用
    kubectl apply -f components.yaml

    # 查看 所有 pod
    kubectl get pod,svc --all-namespaces -o wide

  else

    echo "未启用 Metrics Server 插件 安装"
  fi
}

# 全部去污
function taintNodesAll() {
  kubectl get no -o yaml | grep taint -A 10
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  kubectl get no -o yaml | grep taint -A 10
  kubectl get nodes
  kubectl get pod,svc --all-namespaces -o wide
}

# 系统判断
osName

# 安装、配置 NTP（网络时间协议）
ntpdateInstall

# bash-completion 安装、配置
bashCompletionInstall

# 关闭 selinux
selinuxPermissive

# 停止防火墙
stopFirewalld

# 创建 VIP
availabilityVip

# k8s 版本
k8sVersion

# 主机名判断
hostName

# 网卡选择
interfaceName

# 关闭交换空间
swapOff

# 安装、配置 Docker、containerd
dockerInstall

# 阿里云 kubernetes 仓库
aliyunKubernetesRepo

# k8s 配置
k8sConf

# k8s 安装
k8sInstall

# 拉取镜像
imagesPull

# k8s集群模式
installMode

if [ "$INSTALL_ONLY" == true ]; then
  echo ''
  echo ''
  echo ''
  echo "仅安装，不进行初始化"
else

  if [ "$INSTALL_MODE" == standalone ]; then
    # 单机

    # k8s 初始化
    k8sInit

    # calico 网络插件
    calicoInstall

    # Metrics Server 插件
    metricsServerInstall

    # 使用 VIP 创建主节点时，不去污
    if ! [ "$AVAILABILITY_MASTER" ]; then
      # 全部去污
      taintNodesAll
    fi

    # 等待 pod 就绪
    kubectl wait --for=condition=Ready --all pods --all-namespaces --timeout=600s

  elif [ "$INSTALL_MODE" == master ]; then
    # 主节点

    # k8s 初始化
    k8sInit

    # calico 网络插件
    calicoInstall

    # Metrics Server 插件
    metricsServerInstall

    # 等待 pod 就绪
    kubectl wait --for=condition=Ready --all pods --all-namespaces --timeout=600s

  elif [ "$INSTALL_MODE" == node ]; then
    # 工作节点

    echo ''
    echo ''
    echo ''
    echo "当前节点是工作节点：请运行主节点加入集群的命令，例如：kubeadm join 1.2.3.4:6443 --token abcdef.1234567890abcdef --discovery-token-ca-cert-hash sha256:1234..cdef"
  fi

  if [[ "$INSTALL_MODE" =~ ^(standalone|master)$ ]]; then
    echo ''
    echo ''
    echo ''
    echo 'kubectl get pod --all-namespaces -o wide'
    echo ''
    echo ''
    echo ''
    echo 'SSH 重新连接或者执行 source /etc/profile && source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令'
    echo '执行 kubectl get pod --all-namespaces -o wide，当所有的 pod 均为 Running 说明初始化完成了'
    echo ''
    echo ''
    echo ''
  fi

fi
