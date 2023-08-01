#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：chmod +x k8s.sh && sudo ./k8s.sh
# 仓库：https://jihulab.com/xuxiaowei-com-cn/k8s.sh
# 版本：SNAPSHOT/0.2.0
# 如果发现脚本不能正常运行，可尝试执行：sed -i 's/\r$//' k8s.sh
#

# 一旦有命令返回非零值，立即退出脚本
set -e

# 颜色定义
readonly COLOR_BLUE='\033[34m'
readonly COLOR_GREEN='\033[92m'
readonly COLOR_RED='\033[31m'
readonly COLOR_RESET='\033[0m'
readonly COLOR_YELLOW='\033[93m'

# 定义支持的 kubernetes 版本范围的下限和上限
readonly lower_major=1
readonly lower_minor=24
readonly upper_major=1
readonly upper_minor=27

# 高可用主节点地址
availability_master_array=()

# 高可用 haproxy 默认用户名
availability_haproxy_username=admin
# 高可用 haproxy 默认密码
availability_haproxy_password=password

# kubernetes 网络插件 calico 版本
calico_version=3.25

# 高可用 VIP keepalived 镜像
keepalived_mirror=lettore/keepalived
# 高可用 VIP keepalived 镜像 版本
keepalived_version=3.16-2.2.7

# 高可用 VIP haproxy 镜像
haproxy_mirror=haproxytech/haproxy-debian
# 高可用 VIP haproxy 镜像 版本
haproxy_version=2.8

# 检查 kubernetes 版本号
_check_kubernetes_version_range() {
  local version=$1

  # 检查版本号是否为数字
  if ! [[ $version =~ ^[0-9.]+$ ]]; then
    echo -e "${COLOR_RED}kubernetes 版本号 $version 不支持安装，（版本号只能包含：数字、小数点），退出程序${COLOR_RESET}"
    exit 1
  fi

  # 将版本号拆分成整数和小数部分
  local major=$(echo "$version" | cut -d '.' -f 1)
  local minor=$(echo "$version" | cut -d '.' -f 2)

  echo -e "${COLOR_BLUE}kubernetes 指定主版本号：${COLOR_RESET}${COLOR_GREEN}${major}${COLOR_RESET}"
  echo -e "${COLOR_BLUE}kubernetes 指定次版本号：${COLOR_RESET}${COLOR_GREEN}${minor}${COLOR_RESET}"

  # 比较版本号与范围
  if ! [[ $lower_major -le $major && $major -le $upper_major && $lower_minor -le $minor && $minor -le $upper_minor ]]; then
    echo -e "${COLOR_RED}kubernetes 指定版本号不在支持范围内，退出程序${COLOR_RESET}"
    exit 1
  fi
}

# 检查 网卡名称
_check_interface_name() {
  local name=$1

  if ! command -v ip &>/dev/null; then
    if [[ $ID == anolis || $ID == centos ]]; then
      echo -e "${COLOR_BLUE}当前系统无 ip 命令，开始安装 iproute${COLOR_RESET}"
      sudo yum -y install iproute
    elif [[ $ID == ubuntu ]]; then
      echo -e "${COLOR_BLUE}当前系统无 ip 命令，开始安装 iproute2${COLOR_RESET}"
      sudo apt-get -y install iproute2
    fi
  fi

  if ! ip link show "$name" >/dev/null 2>&1; then
    echo -e "${COLOR_RED}当前系统不存在网卡: ${name}，退出程序${COLOR_RESET}"
    exit 1
  fi
}

_check_availability_vip() {
  local ip=$1

  if ! echo "$ip" | grep -P -q "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"; then
    echo -e "${COLOR_RED}kubernetes 高可用 VIP: ${ip} 不是一个有效 IP，退出程序${COLOR_RESET}"
    exit 1
  fi
}

# 检查 VIP 编号
_check_availability_vip_no() {
  local no=$1

  # 验证 AVAILABILITY_VIP_NO 是否为整数
  if ! [[ $no =~ ^[0-9]+$ ]]; then
    echo -e "${COLOR_RED}VIP 编号 必须是整数，退出程序${COLOR_RESET}"
    exit 1
  fi

  if [[ $no == 1 ]]; then
    availability_vip_state=MASTER
  else
    availability_vip_state=BACKUP
  fi

}

# 检查 主节点地址
_check_availability_master() {
  local master=$1

  # 使用 @ 符号分割主机名和地址
  IFS='@' read -ra parts <<<"$master"
  local name="${parts[0]}"
  local address="${parts[1]}"

  # 使用冒号分割 IP 地址和端口
  IFS=':' read -ra ADDR <<<"$address"
  local ip="${ADDR[0]}"
  local port="${ADDR[1]}"

  # 检查IP地址是否合法
  if ! echo "$ip" | grep -P -q "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"; then
    echo -e "${COLOR_RED}检查 ${master} 时发现，IP地址 ${ip} 不合法，退出程序${COLOR_RESET}"
    exit 1
  fi

  if ! [[ $port =~ ^[0-9]+$ ]]; then
    echo -e "${COLOR_RED}检查 ${master} 时发现，端口 ${port} 必须是整数，退出程序${COLOR_RESET}"
    exit 1
  fi

  # 检查端口是否在合法范围内（1到65535）
  if ((port < 1 || port > 65535)); then
    echo -e "${COLOR_RED}检查 ${master} 时发现，端口 ${port} 不合法，退出程序${COLOR_RESET}"
    exit 1
  fi

  # 将解析结果存入数组
  availability_master_array+=("$name $address")
}

# NTP（网络时间协议） 安装
_ntp_install() {
  if [[ $ntp_disabled == true ]]; then
    echo -e "${COLOR_YELLOW}NTP 安装已被禁用${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}NTP 安装开始${COLOR_RESET}"

    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl
    echo -e "${COLOR_BLUE}时区设置为亚洲/上海${COLOR_RESET}" && sudo timedatectl set-timezone Asia/Shanghai
    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl

    local ntp_conf="/etc/ntp.conf"
    local ntp_conf_backup="${ntp_conf}.$(date +%Y%m%d%H%M%S)"

    if [[ $ID == anolis || $ID == centos ]]; then

      if [[ $VERSION == 7* ]]; then
        sudo yum -y install ntpdate && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

        if [ -f "$ntp_conf" ]; then
          cp "$ntp_conf" "$ntp_conf_backup"
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 已备份为 ${COLOR_RESET}${COLOR_GREEN}${ntp_conf_backup}${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}NTP 开始创建配置文件 ${ntp_conf}${COLOR_RESET}"
        echo "server ntp.aliyun.com" >$ntp_conf
        echo "server ntp1.aliyun.com" >>$ntp_conf
        echo -e "${COLOR_BLUE}NTP 完成创建配置文件 ${ntp_conf}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 查看配置文件 ${ntp_conf} 内容${COLOR_RESET}" && cat $ntp_conf

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntpdate || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart ntpdate
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntpdate
        echo -e "${COLOR_BLUE}NTP 设置开机启动${COLOR_RESET}" && sudo systemctl enable ntpdate
      elif [[ $VERSION == 8* || $VERSION == 23* ]]; then

        local ntp_conf="/etc/chrony.conf"
        local ntp_conf_backup="${ntp_conf}.$(date +%Y%m%d%H%M%S)"

        sudo yum -y install chrony && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

        if [ -f "$ntp_conf" ]; then
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 备份开始${COLOR_RESET}"
          sudo cp "$ntp_conf" "$ntp_conf_backup"
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 备份完成，备份文件名 ${COLOR_RESET}${COLOR_GREEN}${ntp_conf_backup}${COLOR_RESET}"
        fi
        echo -e "${COLOR_BLUE}NTP 开始创建配置文件 ${ntp_conf}${COLOR_RESET}"
        sudo sed -i '/^pool/s/^/#/' $ntp_conf
        echo "pool ntp.aliyun.com iburst" | sudo tee -a $ntp_conf
        echo "pool ntp1.aliyun.com iburst" | sudo tee -a $ntp_conf
        echo -e "${COLOR_BLUE}NTP 完成创建配置文件 ${ntp_conf}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 查看配置文件 ${ntp_conf} 内容${COLOR_RESET}" && cat $ntp_conf

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status chronyd -n 0 || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart chronyd
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status chronyd -n 0
        echo -e "${COLOR_BLUE}NTP 设置开机启动${COLOR_RESET}" && sudo systemctl enable chronyd
      fi
    elif [[ $ID == ubuntu ]]; then
      if [[ $VERSION == 20* ]]; then
        sudo apt-get -y install ntp && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

        if [ -f "$ntp_conf" ]; then
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 备份开始${COLOR_RESET}"
          sudo cp "$ntp_conf" "$ntp_conf_backup"
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 备份完成，备份文件名 ${COLOR_RESET}${COLOR_GREEN}${ntp_conf_backup}${COLOR_RESET}"
        else
          echo "" | sudo tee -a $ntp_conf
        fi
        echo -e "${COLOR_BLUE}NTP 开始修改配置文件 ${ntp_conf}${COLOR_RESET}"
        sudo sed -i '/^pool/s/^/#/' $ntp_conf
        echo "pool ntp.aliyun.com iburst" | sudo tee -a $ntp_conf
        echo "pool ntp1.aliyun.com iburst" | sudo tee -a $ntp_conf
        echo -e "${COLOR_BLUE}NTP 完成修改配置文件 ${ntp_conf}${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 查看配置文件 ${ntp_conf} 内容${COLOR_RESET}" && cat $ntp_conf

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntp || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart ntp
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntp
        echo -e "${COLOR_BLUE}NTP 设置开机启动${COLOR_RESET}" && sudo systemctl enable ntp
      elif [[ $VERSION == 22* ]]; then
        echo -e "${COLOR_YELLOW}Ubuntu 22 NTP 安装已忽略${COLOR_RESET}"
      fi
    fi

    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl

    echo -e "${COLOR_BLUE}NTP 安装结束${COLOR_RESET}"
  fi
}

# bash-completion 安装
_bash_completion_install() {
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}bash-completion 安装开始${COLOR_RESET}"
    sudo yum -y install bash-completion
    source /etc/profile
    echo -e "${COLOR_BLUE}bash-completion 安装完成${COLOR_RESET}"
  fi
}

# 关闭 selinux
_selinux_permissive() {
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}selinux 当前状态${COLOR_RESET}"
    if [[ $(getenforce) == "Disabled" ]]; then
      echo -e "${COLOR_BLUE}selinux 当前状态已禁用${COLOR_RESET}"
    else
      echo -e "${COLOR_BLUE}selinux 当前状态未禁用，开始禁用当前状态${COLOR_RESET}" && sudo setenforce 0
    fi
    echo -e "${COLOR_BLUE}selinux 配置文件${COLOR_RESET}" && cat /etc/selinux/config
    echo -e "${COLOR_BLUE}selinux 永久禁用${COLOR_RESET}" && sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    echo -e "${COLOR_BLUE}selinux 配置文件${COLOR_RESET}" && cat /etc/selinux/config
  fi
}

# 停止 防火墙
_firewalld_stop() {
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}firewalld 关闭${COLOR_RESET}" && sudo systemctl stop firewalld.service
    echo -e "${COLOR_BLUE}firewalld 关闭开机自启${COLOR_RESET}" && sudo systemctl disable firewalld.service
  fi
}

# 关闭 交换空间
_swap_off() {
  echo -e "${COLOR_BLUE}查看当前交换空间${COLOR_RESET}" && free -h
  echo -e "${COLOR_BLUE}关闭交换空间（临时）${COLOR_RESET}" && sudo swapoff -a
  echo -e "${COLOR_BLUE}关闭交换空间（永久）${COLOR_RESET}" && sudo sed -i 's/.*swap.*/#&/' /etc/fstab
  echo -e "${COLOR_BLUE}查看当前交换空间${COLOR_RESET}" && free -h
}

# docker 仓库
_docker_repo() {
  echo -e "${COLOR_BLUE}docker 仓库 添加开始${COLOR_RESET}"
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}安装/更新 curl${COLOR_RESET}" && sudo yum install -y curl
    echo -e "${COLOR_BLUE}增加 docker 仓库${COLOR_RESET}"
    sudo curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo

    if [[ $VERSION == 23* ]]; then
      echo -e "${COLOR_BLUE}兼容 anolis 23${COLOR_RESET}" && sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
    fi

    echo -e "${COLOR_BLUE}查看 docker 仓库${COLOR_RESET}" && cat /etc/yum.repos.d/docker-ce.repo
  elif [[ $ID == ubuntu ]]; then
    echo -e "${COLOR_BLUE}安装 ca-certificates curl gnupg${COLOR_RESET}" && sudo apt-get install -y ca-certificates curl gnupg

    echo -e "${COLOR_BLUE}修改仓库 gpg 秘钥文件夹权限${COLOR_RESET}" && sudo install -m 0755 -d /etc/apt/keyrings

    local docker_gpg_conf=/etc/apt/keyrings/docker.gpg
    local docker_gpg_conf_backup="${docker_gpg_conf}.$(date +%Y%m%d%H%M%S)"
    if [ -f "$docker_gpg_conf" ]; then
      echo -e "${COLOR_BLUE}docker 仓库 gpg 秘钥 ${docker_gpg_conf} 备份开始${COLOR_RESET}"
      sudo mv "$docker_gpg_conf" "$docker_gpg_conf_backup"
      echo -e "${COLOR_BLUE}docker 仓库 gpg 秘钥 ${containerd_conf} 备份完成，备份文件名 ${COLOR_RESET}${COLOR_GREEN}${docker_gpg_conf_backup}${COLOR_RESET}"
    fi

    echo -e "${COLOR_BLUE}添加 docker 仓库 gpg 秘钥${COLOR_RESET}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo -e "${COLOR_BLUE}修改 docker 仓库 gpg 秘钥文件权限${COLOR_RESET}" && sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo -e "${COLOR_BLUE}添加 docker 仓库${COLOR_RESET}"
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    echo -e "${COLOR_BLUE}查看 docker 仓库${COLOR_RESET}" && cat /etc/apt/sources.list.d/docker.list

    echo -e "${COLOR_BLUE}更新 docker 仓库源${COLOR_RESET}" && sudo apt-get update
  fi

  echo -e "${COLOR_BLUE}docker 仓库 添加结束${COLOR_RESET}"
}

# containerd 安装
_containerd_install() {
  echo -e "${COLOR_BLUE}containerd 安装开始${COLOR_RESET}"

  if [[ $ID == anolis || $ID == centos ]]; then
    # https://docs.docker.com/engine/install/centos/

    echo -e "${COLOR_BLUE}卸载旧 docker（不是 docker-ce，目前都是使用的 docker-ce）${COLOR_RESET}"
    sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

    echo -e "${COLOR_BLUE}containerd 安装${COLOR_RESET}" && sudo yum install -y containerd.io
  elif [[ $ID == ubuntu ]]; then
    # https://docs.docker.com/engine/install/ubuntu/

    echo -e "${COLOR_BLUE}卸载旧 docker（不是 docker-ce，目前都是使用的 docker-ce）${COLOR_RESET}"
    sudo apt-get remove docker.io docker-doc docker-compose podman-docker containerd runc || echo ""

    echo -e "${COLOR_BLUE}containerd 安装${COLOR_RESET}" && sudo apt-get install -y containerd.io
  fi

  echo -e "${COLOR_BLUE}停止 containerd${COLOR_RESET}" && sudo systemctl stop containerd.service

  local containerd_conf=/etc/containerd/config.toml
  local containerd_conf_backup="${containerd_conf}.$(date +%Y%m%d%H%M%S)"
  if [ -f "$containerd_conf" ]; then
    echo -e "${COLOR_BLUE}containerd 旧配置文件 ${containerd_conf} 备份开始${COLOR_RESET}"
    sudo cp "$containerd_conf" "$containerd_conf_backup"
    echo -e "${COLOR_BLUE}containerd 旧配置文件 ${containerd_conf} 备份完成，备份文件名 ${COLOR_RESET}${COLOR_GREEN}${containerd_conf_backup}${COLOR_RESET}"
  fi

  echo -e "${COLOR_BLUE}containerd 生成配置文件 ${containerd_conf}${COLOR_RESET}"
  sudo containerd config default | sudo tee $containerd_conf

  echo -e "${COLOR_BLUE}containerd 配置 pause 使用阿里云镜像${COLOR_RESET}"
  sudo sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" $containerd_conf

  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd
  echo -e "${COLOR_BLUE}containerd 配置 systemd cgroup 驱动${COLOR_RESET}"
  sudo sed -i "s#SystemdCgroup = false#SystemdCgroup = true#g" $containerd_conf

  echo -e "${COLOR_BLUE}containerd 配置文件${COLOR_RESET}" && cat $containerd_conf

  echo -e "${COLOR_BLUE}containerd 重启${COLOR_RESET}" && sudo systemctl restart containerd.service
  echo -e "${COLOR_BLUE}containerd 状态${COLOR_RESET}" && sudo systemctl status containerd.service -n 0
  echo -e "${COLOR_BLUE}containerd 设置开机自启${COLOR_RESET}" && sudo systemctl enable containerd.service

  echo -e "${COLOR_BLUE}containerd 安装结束${COLOR_RESET}"
}

# docker-ce 安装
_docker_ce_install() {
  echo -e "${COLOR_BLUE}docker-ce 安装开始${COLOR_RESET}"

  if [[ $ID == anolis || $ID == centos ]]; then
    # https://docs.docker.com/engine/install/centos/

    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif [[ $ID == ubuntu ]]; then
    # https://docs.docker.com/engine/install/ubuntu/

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  echo -e "${COLOR_BLUE}docker-ce 停止${COLOR_RESET}" && sudo systemctl stop docker.service
  echo -e "${COLOR_BLUE}docker-ce 创建 配置文件的文件夹${COLOR_RESET}" && sudo mkdir -p /etc/docker
  echo -e "${COLOR_BLUE}docker-ce 创建 配置文件${COLOR_RESET}"
  sudo tee /etc/docker/daemon.json <<-'EOF'
  {
    "registry-mirrors": ["https://hnkfbj7x.mirror.aliyuncs.com"],
    "exec-opts": ["native.cgroupdriver=systemd"]
  }
EOF
  echo -e "${COLOR_BLUE}docker-ce 配置文件${COLOR_RESET}" && cat /etc/docker/daemon.json
  echo -e "${COLOR_BLUE}docker-ce 重启${COLOR_RESET}" && sudo systemctl restart docker.service
  echo -e "${COLOR_BLUE}docker-ce 状态${COLOR_RESET}" && sudo systemctl status docker.service -n 0
  echo -e "${COLOR_BLUE}docker-ce 设置开机自启${COLOR_RESET}" && sudo systemctl enable docker.service

  echo -e "${COLOR_BLUE}docker-ce 安装结束${COLOR_RESET}"
}

# kubernetes 仓库
_kubernetes_repo() {
  # https://developer.aliyun.com/mirror/kubernetes/

  echo -e "${COLOR_BLUE}kubernetes 仓库 添加开始${COLOR_RESET}"

  if [[ $ID == anolis || $ID == centos ]]; then

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

    echo -e "${COLOR_BLUE}kubernetes 仓库 内容：${COLOR_RESET}${COLOR_GREEN}/etc/yum.repos.d/kubernetes.repo${COLOR_RESET}" && cat /etc/yum.repos.d/kubernetes.repo

  elif [[ $ID == ubuntu ]]; then

    sudo apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    echo -e "${COLOR_BLUE}kubernetes 仓库 内容：${COLOR_RESET}${COLOR_GREEN}/etc/apt/sources.list.d/kubernetes.list${COLOR_RESET}" && cat /etc/apt/sources.list.d/kubernetes.list

    echo -e "${COLOR_BLUE}更新 kubernetes 仓库源${COLOR_RESET}" && sudo apt-get update
  fi

  echo -e "${COLOR_BLUE}kubernetes 仓库 添加结束${COLOR_RESET}"
}

# kubernetes 配置
_kubernetes_conf() {
  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/

  echo -e "${COLOR_BLUE}kubernetes 配置开始${COLOR_RESET}"

  echo -e "${COLOR_BLUE}kubernetes 配置：${COLOR_RESET}${COLOR_GREEN}/etc/modules-load.d/k8s.conf${COLOR_RESET}"
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  echo -e "${COLOR_BLUE}kubernetes 配置：加载 br_netfilter${COLOR_RESET}" && sudo modprobe br_netfilter
  echo -e "${COLOR_BLUE}kubernetes 配置：加载 overlay${COLOR_RESET}" && sudo modprobe overlay

  # 设置所需的 sysctl 参数，参数在重新启动后保持不变

  echo -e "${COLOR_BLUE}kubernetes 配置：${COLOR_RESET}${COLOR_GREEN}/etc/sysctl.d/k8s.conf${COLOR_RESET}"
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  # 应用 sysctl 参数而不重新启动
  echo -e "${COLOR_BLUE}kubernetes 配置：重新加载内核${COLOR_RESET}" && sudo sysctl --system

  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
  # 通过运行以下指令确认 br_netfilter 和 overlay 模块被加载：
  echo -e "${COLOR_BLUE}kubernetes 配置：确认加载 br_netfilter${COLOR_RESET}" && lsmod | grep br_netfilter
  echo -e "${COLOR_BLUE}kubernetes 配置：确认加载 overlay${COLOR_RESET}" && lsmod | grep overlay

  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
  # 通过运行以下指令确认 net.bridge.bridge-nf-call-iptables、net.bridge.bridge-nf-call-ip6tables 和 net.ipv4.ip_forward 系统变量在你的 sysctl 配置中被设置为 1：
  echo -e "${COLOR_BLUE}kubernetes 配置：修改网络${COLOR_RESET}" && sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

  echo -e "${COLOR_BLUE}kubernetes 配置结束${COLOR_RESET}"
}

# 主机名判断
_hostname() {
  ETC_HOSTNAME=$(cat /etc/hostname)
  CMD_HOSTNAME=$(hostname)
  if [[ $CMD_HOSTNAME =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$ ]]; then
    if ! [ "$ETC_HOSTNAME" ]; then
      echo -e "${COLOR_BLUE}主机名符合要求${COLOR_RESET}"
    elif [ "$ETC_HOSTNAME" == "$CMD_HOSTNAME" ]; then
      echo -e "${COLOR_BLUE}主机名符合要求${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}临时主机名：$CMD_HOSTNAME${COLOR_RESET}"
      echo -e "${COLOR_RED}配置文件主机名：$ETC_HOSTNAME${COLOR_RESET}"
      echo -e "${COLOR_RED}临时主机名符合要求，但是配置文件与临时主机名不同，系统重启后，将使用配置文件主机名，可能造成 k8s 无法正常运行。${COLOR_RESET}"
      echo -e "${COLOR_RED}由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请将配置文件 /etc/hostname 中的主机名与命令 hostname 修改成一致的名称。${COLOR_RESET}"
      echo -e "${COLOR_RED}hostname 是临时主机名，重启后使用 /etc/hostname 文件中的内容作为主机名。${COLOR_RESET}"
      exit 1
    fi
  else
    echo -e "${COLOR_RED}主机名不符合要求${COLOR_RESET}"
    echo -e "${COLOR_RED}主机名必须符合小写的 RFC 1123 子域，必须由小写字母数字字符“-”或“.”组成，并且必须以字母数字字符开头和结尾${COLOR_RESET}"
    echo -e "${COLOR_RED}由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请自行修改。${COLOR_RESET}"
    exit 1
  fi
}

# kubernetes 安装
_kubernetes_install() {
  echo -e "${COLOR_BLUE}kubernetes 安装开始${COLOR_RESET}"

  # 主机名判断
  _hostname

  if [[ $ID == anolis || $ID == centos ]]; then
    if [ "$kubernetes_version" ]; then
      echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
      sudo yum install -y kubelet-"$kubernetes_version"-0 kubeadm-"$kubernetes_version"-0 kubectl-"$kubernetes_version"-0 --disableexcludes=kubernetes --nogpgcheck
    else
      echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}最新版${COLOR_RESET}"
      sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
    fi
  elif [[ $ID == ubuntu ]]; then

    if [ "$kubernetes_version" ]; then
      echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
      sudo apt-get install -y kubelet="$kubernetes_version"-00 kubeadm="$kubernetes_version"-00 kubectl="$kubernetes_version"-00
    else
      echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}最新版${COLOR_RESET}"
      sudo apt-get install -y kubelet kubeadm kubectl
    fi
  fi
  echo -e "${COLOR_BLUE}线程守护${COLOR_RESET}" && sudo systemctl daemon-reload
  echo -e "${COLOR_GREEN}kubelet${COLOR_RESET}${COLOR_BLUE} 重启${COLOR_RESET}" && sudo systemctl restart kubelet
  echo -e "${COLOR_GREEN}kubelet${COLOR_RESET}${COLOR_BLUE} 设置开机自启${COLOR_RESET}" && sudo systemctl enable kubelet
  echo -e "${COLOR_BLUE}kubernetes 安装结束${COLOR_RESET}"
}

# kubernetes 初始化
_kubernetes_init() {
  if [[ $kubernetes_init_skip != true ]]; then
    echo -e "${COLOR_BLUE}kubernetes 初始化开始${COLOR_RESET}"

    if [[ $availability_vip ]]; then
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 高可用 VIP ${availability_vip} 初始化时使用的镜像版本 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version" --control-plane-endpoint "$availability_vip:9443" --upload-certs
      else
        echo -e "${COLOR_BLUE}kubernetes 高可用 VIP ${availability_vip} 初始化时使用当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}"
        kubeadm init --image-repository=registry.aliyuncs.com/google_containers --control-plane-endpoint "$availability_vip:9443" --upload-certs
      fi
    else
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 初始化时使用的镜像版本 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        kubeadm init --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version"
      else
        echo -e "${COLOR_BLUE}kubernetes 初始化时使用当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}"
        kubeadm init --image-repository=registry.aliyuncs.com/google_containers
      fi
    fi

    echo -e "${COLOR_BLUE}在环境变量文件 ${COLOR_RESET}${COLOR_GREEN}/etc/profile${COLOR_RESET} 中配置 ${COLOR_GREEN}KUBECONFIG=/etc/kubernetes/admin.conf${COLOR_RESET}"
    sudo bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/profile"
    echo -e "${COLOR_BLUE}授权 ${COLOR_RESET}${COLOR_GREEN}/etc/kubernetes/admin.conf${COLOR_RESET} 文件其他人能访问${COLOR_RESET}"
    sudo chmod a+r /etc/kubernetes/admin.conf
    echo -e "${COLOR_BLUE}刷新环境变量${COLOR_RESET}"
    source /etc/profile

    # https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-linux/#optional-kubectl-configurations

    echo -e "${COLOR_BLUE}启动 kubectl 自动补全功能${COLOR_RESET}"
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null
    sudo chmod a+r /etc/bash_completion.d/kubectl
    echo -e "${COLOR_BLUE}源引 ~/.bashrc 文件${COLOR_RESET}"
    source ~/.bashrc

    echo -e "${COLOR_BLUE}显示群集信息${COLOR_RESET}" && kubectl cluster-info
    echo -e "${COLOR_BLUE}显示 node 信息${COLOR_RESET}" && kubectl get nodes
    echo -e "${COLOR_BLUE}显示 pod 信息${COLOR_RESET}" && kubectl get pod --all-namespaces -o wide
    echo -e "${COLOR_BLUE}显示 svc 信息${COLOR_RESET}" && kubectl get svc --all-namespaces -o wide

    echo -e "${COLOR_BLUE}kubernetes 初始化结束${COLOR_RESET}"

    echo ""

    echo -e "${COLOR_BLUE}SSH 重新连接或者执行 source /etc/profile && source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubectl get pod --all-namespaces -o wide${COLOR_RESET}"

    echo ""
  fi
}

# 网卡
_interface_name() {
  if ! [[ $interface_name ]]; then
    interface_name=$(ip route get 223.5.5.5 | grep -oP '(?<=dev\s)\w+' | head -n 1)
    if [ "$interface_name" ]; then
      echo -e "${COLOR_BLUE}上网网卡是 ${COLOR_RESET}${COLOR_GREEN}${interface_name}${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}未找到上网网卡，停止安装${COLOR_RESET}"
      exit 1
    fi
  fi
}

# kubernetes 网络插件 calico 安装
function _calico_init() {
  if [[ $calico_init_skip != true ]]; then
    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 初始化开始${COLOR_RESET}"

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 使用版本：${COLOR_RESET}${COLOR_GREEN}${calico_version}${COLOR_RESET}"
    curl -o calico.yaml https://docs.tigera.io/archive/v"$calico_version"/manifests/calico.yaml

    # 网卡
    _interface_name

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 使用网卡：${COLOR_RESET}${COLOR_GREEN}${interface_name}${COLOR_RESET}"

    sed -i '/k8s,bgp/a \            - name: IP_AUTODETECTION_METHOD\n              value: "interface=INTERFACE_NAME"' calico.yaml
    sed -i "s#INTERFACE_NAME#$interface_name#g" calico.yaml

    if [ "$calico_mirrors" ]; then
      echo "接收到参数 calico_mirrors：$calico_mirrors"
      sed -i "s#docker\.io#$calico_mirrors#g" calico.yaml
    fi

    kubectl apply -f calico.yaml
    kubectl get nodes
    kubectl get pod,svc --all-namespaces -o wide

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 初始化结束${COLOR_RESET}"

    echo ""

    echo -e "${COLOR_BLUE}SSH 重新连接或者执行 source /etc/profile && source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubectl get pod --all-namespaces -o wide${COLOR_RESET}"

    echo ""
  fi
}

# 高可用 VIP haproxy 安装
_availability_haproxy_install() {

  local container_name=k8s-haproxy

  if docker ps -a --format "{{.Names}}" | grep -Eq "^$container_name$"; then
    echo -e "${COLOR_YELLOW}$container_name 容器已存在，不会重复创建${COLOR_RESET}"
  else

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
    stats auth           $availability_haproxy_username:$availability_haproxy_password
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
    for master in "${availability_master_array[@]}"; do
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
      "${haproxy_mirror}:${haproxy_version}"
  fi
}

# 高可用 VIP keepalived 安装
_availability_keepalived_install() {

  local container_name=k8s-keepalived

  if docker ps -a --format "{{.Names}}" | grep -Eq "^$container_name$"; then
    echo -e "${COLOR_YELLOW}$container_name 容器已存在，不会重复创建${COLOR_RESET}"
  else

    # 网卡
    _interface_name

    mkdir -p /etc/kubernetes/

    cat >/etc/kubernetes/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   router_id LVS_$availability_vip_no
}

vrrp_script checkhaproxy
{
    script "/usr/bin/check-haproxy.sh"
    interval 2
    weight -30
}

vrrp_instance VI_1 {
    state $availability_vip_state
    interface $interface_name
    virtual_router_id 51
    priority 100
    advert_int 1

    virtual_ipaddress {
        $availability_vip/24 dev $interface_name
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
      "${keepalived_mirror}:${keepalived_version}" \
      --copy-service
  fi

}

. /etc/os-release
echo -e "${COLOR_BLUE}当前系统名：${COLOR_RESET}${COLOR_GREEN}${NAME}${COLOR_RESET}"
echo -e "${COLOR_BLUE}当前系统版本：${COLOR_RESET}${COLOR_GREEN}${VERSION}${COLOR_RESET}"
echo -e "${COLOR_BLUE}当前系统ID：${COLOR_RESET}${COLOR_GREEN}${ID}${COLOR_RESET}"

if [[ $ID == anolis ]]; then
  if [[ $VERSION != 7* && $VERSION != 8* && $VERSION != 23* ]]; then
    echo -e "${COLOR_RED}不支持 ${VERSION} 版本的 ${ID}${COLOR_RESET}"
    exit 1
  fi
elif [[ $ID == centos ]]; then
  if [[ $VERSION != 7* && $VERSION != 8* ]]; then
    echo -e "${COLOR_RED}不支持 ${VERSION} 版本的 ${ID}${COLOR_RESET}"
    exit 1
  fi
elif [[ $ID == ubuntu ]]; then
  if ! [[ $VERSION == 20* || $VERSION == 22* ]]; then
    echo -e "${COLOR_RED}不支持 ${VERSION} 版本的 ${ID}${COLOR_RESET}"
    exit 1
  fi

  echo -e "${COLOR_BLUE}更新 ${ID} 仓库源${COLOR_RESET}" && sudo apt-get update
else
  echo -e "${COLOR_RED}不支持 ${ID} 系统${COLOR_RESET}"
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in

  docker-install | -docker-install | --docker-install)
    docker_install=true
    echo -e "${COLOR_BLUE}启用 docker-ce 安装${COLOR_RESET}"
    ;;

  kubernetes-version=* | -kubernetes-version=* | --kubernetes-version=*)
    kubernetes_version="${1#*=}"

    echo -e "${COLOR_BLUE}支持安装的 kubernetes 版本号：${COLOR_RESET}${COLOR_GREEN}${lower_major}.${lower_minor}~${upper_major}.${upper_minor}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubernetes 指定版本号：${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"

    _check_kubernetes_version_range "$kubernetes_version"
    ;;

  kubernetes-init-skip | -kubernetes-init-skip | --kubernetes-init-skip)
    kubernetes_init_skip=true
    echo -e "${COLOR_BLUE}跳过 kubernetes 初始化${COLOR_RESET}"
    ;;

  calico-init-skip | -calico-init-skip | --calico-init-skip)
    calico_init_skip=true
    echo -e "${COLOR_BLUE}跳过 calico 安装${COLOR_RESET}"
    ;;

  calico-version=* | -calico-version=* | --calico-version=*)
    calico_version="${1#*=}"

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 指定版本号：${COLOR_RESET}${COLOR_GREEN}${calico_version}${COLOR_RESET}"
    ;;

  ntp-disabled | -ntp-disabled | --ntp-disabled)
    ntp_disabled=true
    ;;

  interface-name=* | -interface-name=* | --interface-name=*)
    interface_name="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 指定网卡名：${COLOR_RESET}${COLOR_GREEN}${interface_name}${COLOR_RESET}"

    _check_interface_name "$interface_name"
    ;;

  availability-vip=* | -availability-vip=* | --availability-vip=*)
    availability_vip="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 VIP：${COLOR_RESET}${COLOR_GREEN}${availability_vip}${COLOR_RESET}"

    _check_availability_vip "$availability_vip"
    ;;

  availability-vip-install | -availability-vip-install | --availability-vip-install)
    availability_vip_install=true
    ;;

  availability-vip-no=* | -availability-vip-no=* | --availability-vip-no=*)
    availability_vip_no="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 编号：${COLOR_RESET}${COLOR_GREEN}${availability_vip_no}${COLOR_RESET}"

    _check_availability_vip_no "$availability_vip_no"
    ;;

  calico-mirrors=* | -calico-mirrors=* | --calico-mirrors=*)
    calico_mirrors="${1#*=}"
    ;;

  keepalived-mirror=* | -keepalived-mirror=* | --keepalived-mirror=*)
    keepalived_mirror="${1#*=}"
    ;;

  keepalived-version=* | -keepalived-version=* | --keepalived-version=*)
    keepalived_version="${1#*=}"
    ;;

  haproxy-mirror=* | -haproxy-mirror=* | --haproxy-mirror=*)
    haproxy_mirror="${1#*=}"
    ;;

  haproxy-version=* | -haproxy-version=* | --haproxy-version=*)
    haproxy_version="${1#*=}"
    ;;

  availability-master=* | -availability-master=* | --availability-master=*)
    availability_master="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用主节点地址$((${#availability_master_array[@]} + 1))：${COLOR_RESET}${COLOR_GREEN}${availability_master}${COLOR_RESET}"

    _check_availability_master "$availability_master"
    ;;

  availability-haproxy-username=* | -availability-haproxy-username=* | --availability-haproxy-username=*)
    availability_haproxy_username="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 haproxy 指定用户名：${COLOR_RESET}${COLOR_GREEN}${availability_haproxy_username}${COLOR_RESET}"

    ;;

  availability-haproxy-password=* | -availability-haproxy-password=* | --availability-haproxy-password=*)
    availability_haproxy_password="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 haproxy 指定密码：${COLOR_RESET}${COLOR_GREEN}${availability_haproxy_password}${COLOR_RESET}"

    ;;

  *)
    echo -e "${COLOR_RED}无效参数: $1，退出程序${COLOR_RESET}"
    exit 1
    ;;
  esac
  shift
done

# NTP（网络时间协议） 安装
_ntp_install

# bash-completion 安装
_bash_completion_install

# 关闭 selinux
_selinux_permissive

# 停止 防火墙
_firewalld_stop

# 关闭 交换空间
_swap_off

# docker 仓库
_docker_repo

# containerd 安装
_containerd_install

if [[ $docker_install == true ]]; then
  # docker-ce 安装
  _docker_ce_install
fi

# 高可用 VIP 安装
if [[ $availability_vip_install == true ]]; then
  echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 安装开始${COLOR_RESET}"

  if ! [[ $availability_vip ]]; then
    echo -e "${COLOR_RED}高可用 VIP 不存在，退出程序${COLOR_RESET}"
    exit 1
  fi

  if ! [[ $availability_vip_no ]]; then
    echo -e "${COLOR_RED}VIP 编号 不存在，退出程序${COLOR_RESET}"
    exit 1
  fi

  if [ ${#availability_master_array[@]} -lt 1 ]; then
    echo -e "${COLOR_RED}kubernetes 高可用主节点地址不能为空，退出程序${COLOR_RESET}"
    exit 1
  fi

  # docker-ce 安装
  _docker_ce_install

  # 高可用 VIP haproxy 安装
  _availability_haproxy_install

  # 高可用 VIP keepalived 安装
  _availability_keepalived_install

  echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 安装结束${COLOR_RESET}"
  exit 0
fi

# kubernetes 仓库
_kubernetes_repo

# kubernetes 配置
_kubernetes_conf

# kubernetes 安装
_kubernetes_install

# kubernetes 初始化
_kubernetes_init

# kubernetes 网络插件 calico 初始化
_calico_init
