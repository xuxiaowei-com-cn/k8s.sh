#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：chmod +x install.sh && ./install.sh
# 仓库：https://jihulab.com/xuxiaowei-com-cn/k8s.sh
#

ETC_HOSTNAME=$(cat /etc/hostname)
CMD_HOSTNAME=$(hostname)

# 系统判断
function osName() {
  if grep -q "CentOS" /etc/os-release; then
    echo "当前系统是 CentOS"
  elif grep -q "Anolis" /etc/os-release; then
    echo "系统是 Anolis"
  else
    echo "系统不是 CentOS 或 Anolis，不支持，停止安装"
    exit 1
  fi
}

# 主机名判断
function hostName() {
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
  sudo yum -y install ntpdate
  sudo ntpdate ntp1.aliyun.com
  sudo systemctl status ntpdate
  sudo systemctl start ntpdate
  sudo systemctl status ntpdate
  sudo systemctl enable ntpdate
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
  sudo yum install -y yum-utils
  sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # 搜索 docker 版本
  # yum --showduplicates list docker-ce

  # 安装 docker
  sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # 启动 docker 时，会启动 containerd
  # sudo systemctl status containerd.service
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
  # sudo systemctl status containerd.service

  # sudo systemctl status docker.service
  sudo systemctl start docker.service
  # sudo systemctl status docker.service
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

  sudo systemctl status docker.service
  sudo systemctl status containerd.service
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
  sudo yum install -y kubelet-1.24.0-0 kubeadm-1.24.0-0 kubectl-1.24.0-0 --disableexcludes=kubernetes --nogpgcheck
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo systemctl enable kubelet
}

# k8s 初始化
function k8sInit() {
  kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v1.24.0
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
  curl -o calico.yaml https://docs.tigera.io/archive/v3.25/manifests/calico.yaml
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

# 主机名判断
hostName

# 网卡选择
interfaceName

# 安装、配置 NTP（网络时间协议）
ntpdateInstall

# bash-completion 安装、配置
bashCompletionInstall

# 停止防火墙
stopFirewalld

# 关闭交换空间
swapOff

# 关闭 selinux
selinuxPermissive

# 安装、配置 Docker、containerd
dockerInstall

# 阿里云 kubernetes 仓库
aliyunKubernetesRepo

# k8s 配置
k8sConf

# k8s 安装
k8sInstall

# k8s 初始化
k8sInit

# calico 网络插件
calicoInstall

# 全部去污
taintNodesAll

echo 'SSH 重新连接或者执行 source /etc/profile、source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令'
echo '执行 kubectl get pod --all-namespaces -o wide，当所有的 pod 均为 Running 说明初始化完成了'
