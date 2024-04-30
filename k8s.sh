#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：chmod +x k8s.sh && sudo ./k8s.sh
# 仓库：https://framagit.org/xuxiaowei-com-cn/k8s.sh
# 版本：SNAPSHOT/0.2.0
# 如果发现脚本不能正常运行，可尝试执行：sed -i 's/\r$//' k8s.sh
# 代码格式使用：https://github.com/mvdan/sh
# 代码格式化命令：
# shfmt -l -w -i 2 .\k8s.sh
# shfmt -l -w -i 2 k8s.sh
#

# 一旦有命令返回非零值，立即退出脚本
set -e

# 颜色定义
readonly COLOR_BLUE='\033[34m'
readonly COLOR_GREEN='\033[92m'
readonly COLOR_RED='\033[31m'
readonly COLOR_RESET='\033[0m'
readonly COLOR_YELLOW='\033[93m'

# systemd 最低目标版本
readonly systemd_target_version=systemd-219-42.el7.x86_64

# kernel 最低目标版本
readonly kernel_target_version=3.10.0-957.el7.x86_64

# 定义支持的 kubernetes 版本范围的下限和上限
readonly lower_major=1
readonly lower_minor=24
readonly upper_major=1
readonly upper_minor=30

kubernetes_repo_new_version=1.30

# 高可用主节点地址
availability_master_array=()

# 高可用 haproxy 默认用户名
availability_haproxy_username=admin
# 高可用 haproxy 默认密码
availability_haproxy_password=password

# kubernetes 网络插件 calico 版本
calico_version=3.27.3

# 高可用 VIP keepalived 镜像
keepalived_mirror=lettore/keepalived
# 高可用 VIP keepalived 镜像 版本
keepalived_version=3.16-2.2.7

# 高可用 VIP haproxy 镜像
haproxy_mirror=haproxytech/haproxy-debian
# 高可用 VIP haproxy 镜像 版本
haproxy_version=2.8

# Metrics Server 版本号
metrics_server_version=0.7.1
# Metrics Server 镜像
metrics_server_mirror=registry.aliyuncs.com/google_containers/metrics-server

# 统信 fuse-overlayfs 镜像
uos_fuse_overlayfs_mirror=https://mirrors.aliyun.com/centos/8.5.2111/AppStream/x86_64/os/Packages/fuse-overlayfs-0.7.8-1.module_el8.5.0+1004+c00a74f5.x86_64.rpm
# 统信 slirp4netns 镜像
uos_slirp4netns_mirror=https://mirrors.aliyun.com/centos/8.5.2111/AppStream/x86_64/os/Packages/slirp4netns-0.4.2-3.git21fdece.module_el8.5.0+1004+c00a74f5.x86_64.rpm

# docker 仓库类型
# 可使用：空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
docker_repo_type=

# ingress nginx 版本
ingress_nginx_version=1.10.0

# ingress nginx 相关镜像（前缀）
# 用于替换国内不可访问的 registry.k8s.io/ingress-nginx/controller 镜像
ingress_nginx_controller_mirror=xuxiaoweicomcn/ingress-nginx-controller
# 用于替换国内不可访问的 registry.k8s.io/ingress-nginx/kube-webhook-certgen
ingress_nginx_kube_webhook_certgen_mirror=xuxiaoweicomcn/ingress-nginx-kube-webhook-certgen
# hostNetwork 配置
ingress_nginx_host_network=false

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

# 版本号比较
_compare_version() {
  local version=$1
  local target_version=$2

  # 相等
  if [[ "$version" == "$target_version" ]]; then
    echo "${version} 与 ${target_version} 相等"
    return 0
  fi

  # 将 - 替换成 .
  local version_replace=${version//-/.}
  local target_version_replace=${target_version//-/.}

  # 使用 . 作为分隔符
  IFS="." read -ra version_replace_split <<<"$version_replace"
  IFS="." read -ra target_version_replace_split <<<"$target_version_replace"

  # 获取长度
  local version_replace_split_length=${#version_replace_split[@]}
  local target_version_replace_split_length=${#target_version_replace_split[@]}

  if [[ $version_replace_split_length -lt $target_version_replace_split_length ]]; then
    local min=$version_replace_split_length
  else
    local min=$target_version_replace_split_length
  fi

  # 逐个比较
  for ((i = 0; i < min; i++)); do
    if [[ ${version_replace_split[$i]} -lt ${target_version_replace_split[$i]} ]]; then
      echo "${version} 小于 ${target_version}"
      return 1
      break
    fi
  done

  echo "${version} 大于 ${target_version}"
  return 2
}

# 检查 网卡名称
_check_interface_name() {
  local name=$1

  if ! command -v ip &>/dev/null; then
    if [[ $ID == anolis || $ID == centos ]]; then
      echo -e "${COLOR_BLUE}当前系统 ${ID} 无 ip 命令，开始安装 iproute${COLOR_RESET}"
      sudo yum -y install iproute
    elif [[ $ID == ubuntu ]]; then
      echo -e "${COLOR_BLUE}当前系统 ${ID} 无 ip 命令，开始安装 iproute2${COLOR_RESET}"
      sudo apt-get -y install iproute2
    fi
  fi

  if ! ip link show "$name" >/dev/null 2>&1; then
    echo -e "${COLOR_RED}当前系统 ${ID} 不存在网卡: ${name}，退出程序${COLOR_RESET}"
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

  echo -e "${COLOR_BLUE}检查/处理 主节点地址 ${master} 开始${COLOR_RESET}"

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

  echo -e "${COLOR_BLUE}检查/处理 主节点地址 ${master} 结束${COLOR_RESET}"
}

# NTP（网络时间协议） 安装
_ntp_install() {
  if [[ $ntp_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}NTP 安装已被跳过${COLOR_RESET}"
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

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntpdate --no-pager || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart ntpdate
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntpdate --no-pager
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

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status chronyd --no-pager || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart chronyd
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status chronyd --no-pager
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

        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntp --no-pager || echo -e "${COLOR_YELLOW}NTP 未正常运行${COLOR_RESET}"
        echo -e "${COLOR_BLUE}NTP 重启${COLOR_RESET}" && sudo systemctl restart ntp
        echo -e "${COLOR_BLUE}NTP 查看状态${COLOR_RESET}" && sudo systemctl status ntp --no-pager
        echo -e "${COLOR_BLUE}NTP 设置开机启动${COLOR_RESET}" && sudo systemctl enable ntp
      elif [[ $VERSION == 22* ]]; then
        echo -e "${COLOR_YELLOW}Ubuntu 22 NTP 安装已忽略${COLOR_RESET}"
      fi
    fi

    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl

    echo -e "${COLOR_BLUE}NTP 安装结束${COLOR_RESET}"
  fi
}

# ca-certificates 安装
_ca_certificates_install() {
  if [[ $ca_certificates_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}ca-certificates 安装 已被跳过${COLOR_RESET}"
  else
    if [[ $ID == centos ]]; then
      if [[ $VERSION == 7* ]]; then
        echo -e "${COLOR_BLUE}${ID} ${VERSION} ca-certificates 安装开始${COLOR_RESET}"
        sudo yum -y install ca-certificates
        echo -e "${COLOR_BLUE}${ID} ${VERSION} ca-certificates 安装结束${COLOR_RESET}"
      fi
    fi
  fi
}

# bash-completion 安装
_bash_completion_install() {
  if [[ $bash_completion_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}bash-completion 安装 已被跳过${COLOR_RESET}"
  else
    if [[ $ID == anolis || $ID == centos || $ID = openEuler ]]; then
      echo -e "${COLOR_BLUE}bash-completion 安装开始${COLOR_RESET}"
      sudo yum -y install bash-completion
      source /etc/profile
      . /etc/os-release
      echo -e "${COLOR_BLUE}bash-completion 安装完成${COLOR_RESET}"
    fi
  fi
}

# 关闭 selinux
_selinux_permissive() {
  if [[ $selinux_permissive_skip == true ]]; then
    echo -e "${COLOR_YELLOW}关闭 selinux 已被跳过${COLOR_RESET}"
  else
    if [[ $ID == anolis || $ID == centos || $ID = openEuler ]]; then
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
  fi
}

# 停止 防火墙
_firewalld_stop() {
  if [[ $firewalld_stop_skip == true ]]; then
    echo -e "${COLOR_YELLOW}停止 防火墙 已被跳过${COLOR_RESET}"
  else
    if [[ $ID == centos && $(cat /etc/redhat-release) == *"CentOS Linux release 7.2"* ]]; then
      active_status=$(systemctl is-active iptables || true)

      if [[ $active_status == "inactive" || $active_status == "unknown" ]]; then
        echo -e "${COLOR_BLUE}防火墙 已关闭，无需操作${COLOR_RESET}"
      else
        echo -e "${COLOR_BLUE}防火墙 未关闭，正在进行关闭${COLOR_RESET}" && sudo systemctl stop iptables.service && echo -e "${COLOR_BLUE}防火墙 已关闭${COLOR_RESET}"
      fi
    elif [[ $ID == anolis || $ID == centos || $ID == uos || $ID = openEuler ]]; then
      active_status=$(systemctl is-active firewalld || true)
      enabled_status=$(systemctl is-enabled firewalld || true)

      if [[ $active_status == "inactive" || $active_status == "unknown" ]]; then
        echo -e "${COLOR_BLUE}防火墙 已关闭，无需操作${COLOR_RESET}"
      else
        echo -e "${COLOR_BLUE}防火墙 未关闭，正在进行关闭${COLOR_RESET}" && sudo systemctl stop firewalld.service && echo -e "${COLOR_BLUE}防火墙 已关闭${COLOR_RESET}"
      fi

      if [[ $enabled_status == "disabled" || $enabled_status == "unknown" ]]; then
        echo -e "${COLOR_BLUE}防火墙开机自启 已关闭，无需操作${COLOR_RESET}"
      else
        echo -e "${COLOR_BLUE}防火墙开机自启 未关闭，正在进行关闭${COLOR_RESET}" && sudo systemctl disable firewalld.service && echo -e "${COLOR_BLUE}防火墙开机自启 已关闭${COLOR_RESET}"
      fi
    fi
  fi
}

# 关闭 交换空间
_swap_off() {
  if [[ $swap_off_skip == true ]]; then
    echo -e "${COLOR_YELLOW}关闭 交换空间 swap 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}查看当前交换空间${COLOR_RESET}" && free -h
    echo -e "${COLOR_BLUE}关闭交换空间（临时）${COLOR_RESET}" && sudo swapoff -a
    echo -e "${COLOR_BLUE}关闭交换空间（永久）${COLOR_RESET}" && sudo sed -i 's/.*swap.*/#&/' /etc/fstab
    echo -e "${COLOR_BLUE}查看当前交换空间${COLOR_RESET}" && free -h
  fi
}

# docker 仓库
_docker_repo() {
  if [[ $docker_repo_skip == true ]]; then
    echo -e "${COLOR_YELLOW}添加 docker 仓库 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}docker 仓库 添加开始${COLOR_RESET}"
    if [[ $ID == anolis || $ID == centos || $ID == uos || $ID == openEuler ]]; then
      # https://docs.docker.com/engine/install/centos/

      echo -e "${COLOR_BLUE}安装/更新 curl${COLOR_RESET}" && sudo yum install -y curl
      echo -e "${COLOR_BLUE}增加 docker 仓库${COLOR_RESET}"

      # 空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
      if [[ $docker_repo_type == aliyun ]]; then
        sudo curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
      elif [[  $docker_repo_type == tencent ]]; then
        sudo curl -o /etc/yum.repos.d/docker-ce.repo http://mirrors.cloud.tencent.com/docker-ce/linux/centos/docker-ce.repo
        sudo sed -i "s#https://download.docker.com/linux/centos/#http://mirrors.cloud.tencent.com/docker-ce/linux/centos/#g" /etc/yum.repos.d/docker-ce.repo
      else
        sudo curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
      fi

      if [[ $ID == uos || $ID = openEuler || $VERSION == 23* ]]; then
        echo -e "${COLOR_BLUE}兼容 ${ID} ${VERSION}${COLOR_RESET}" && sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
      fi

      echo -e "${COLOR_BLUE}查看 docker 仓库${COLOR_RESET}" && cat /etc/yum.repos.d/docker-ce.repo
    elif [[ $ID == ubuntu || $ID == openkylin ]]; then
      # https://docs.docker.com/engine/install/ubuntu/

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
      if [[ $ID == openkylin ]]; then
        # 空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
        if [[ $docker_repo_type == aliyun ]]; then
          curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        elif [[ $docker_repo_type == tencent ]]; then
          curl -fsSL http://mirrors.cloud.tencent.com/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        else
          curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        fi
      else
        # 空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
        if [[ $docker_repo_type == aliyun ]]; then
          curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        elif [[ $docker_repo_type == tencent ]]; then
          curl -fsSL http://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        else
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        fi
      fi
      echo -e "${COLOR_BLUE}修改 docker 仓库 gpg 秘钥文件权限${COLOR_RESET}" && sudo chmod a+r /etc/apt/keyrings/docker.gpg

      echo -e "${COLOR_BLUE}添加 docker 仓库${COLOR_RESET}"

      if [[ $ID == openkylin ]]; then
        # 空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
        if [[ $docker_repo_type == aliyun ]]; then
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian \
            buster stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        elif [[ $docker_repo_type == tencent ]]; then
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] http://mirrors.cloud.tencent.com/docker-ce/linux/debian/ \
            buster stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        else
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
            buster stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi
      else
        # 空（官方，默认）、aliyun（阿里云）、tencent（腾讯云）
        if [[ $docker_repo_type == aliyun ]]; then
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        elif [[ $docker_repo_type == tencent ]]; then
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] http://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu/ \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        else
          echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi
      fi

      echo -e "${COLOR_BLUE}查看 docker 仓库${COLOR_RESET}" && cat /etc/apt/sources.list.d/docker.list

      echo -e "${COLOR_BLUE}更新 docker 仓库源${COLOR_RESET}" && sudo apt-get update
    fi

    echo -e "${COLOR_BLUE}docker 仓库 添加结束${COLOR_RESET}"
  fi
}

# containerd 安装
_containerd_install() {
  if [[ $containerd_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}安装 containerd 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}containerd 安装开始${COLOR_RESET}"

    if [[ $ID == anolis || $ID == centos || $ID == uos || $ID = openEuler ]]; then
      # https://docs.docker.com/engine/install/centos/

      echo -e "${COLOR_BLUE}卸载旧 docker（不是 docker-ce，目前都是使用的 docker-ce）${COLOR_RESET}"
      sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

      if [[ $ID == uos ]]; then
        echo -e "${COLOR_BLUE}containerd 安装${COLOR_RESET}" && sudo yum install -y containerd.io.x86_64
      else
        echo -e "${COLOR_BLUE}containerd 安装${COLOR_RESET}" && sudo yum install -y containerd.io
      fi

    elif [[ $ID == ubuntu || $ID == openkylin ]]; then
      # https://docs.docker.com/engine/install/ubuntu/

      echo -e "${COLOR_BLUE}卸载旧 docker（不是 docker-ce，目前都是使用的 docker-ce）${COLOR_RESET}"
      sudo apt-get remove docker.io docker-doc docker-compose podman-docker containerd runc || echo ""

      echo -e "${COLOR_BLUE}containerd 安装${COLOR_RESET}" && sudo apt-get install -y containerd.io
    fi

    echo -e "${COLOR_BLUE}停止 containerd${COLOR_RESET}" && sudo systemctl stop containerd.service

    sudo mkdir -p /etc/containerd

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
    echo -e "${COLOR_BLUE}containerd 状态${COLOR_RESET}" && sudo systemctl status containerd.service --no-pager
    echo -e "${COLOR_BLUE}containerd 设置开机自启${COLOR_RESET}" && sudo systemctl enable containerd.service

    echo -e "${COLOR_BLUE}containerd 安装结束${COLOR_RESET}"
  fi
}

# docker-ce 安装
_docker_ce_install() {
  if [[ $docker_ce_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}安装 docker-ce 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}docker-ce 安装开始${COLOR_RESET}"

    if [[ $ID == anolis || $ID == centos || $ID == uos || $ID = openEuler ]]; then
      # https://docs.docker.com/engine/install/centos/

      if [[ $ID == uos ]]; then
        if [[ $uos_fuse_overlayfs_mirror ]]; then
          yum -y install $uos_fuse_overlayfs_mirror
        else
          echo -e "${COLOR_YELLOW}UOS 跳过安装 fuse-overlayfs${COLOR_RESET}"
        fi
        if [[ $uos_slirp4netns_mirror ]]; then
          yum -y install $uos_slirp4netns_mirror
        else
          echo -e "${COLOR_YELLOW}UOS 跳过安装 slirp4netns${COLOR_RESET}"
        fi
      fi

      sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [[ $ID == ubuntu || $ID == openkylin ]]; then
      # https://docs.docker.com/engine/install/ubuntu/

      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    echo -e "${COLOR_BLUE}docker-ce 停止${COLOR_RESET}"
    sudo systemctl stop docker.socket
    sudo systemctl stop docker.service
    echo -e "${COLOR_BLUE}docker-ce 创建 配置文件的文件夹${COLOR_RESET}" && sudo mkdir -p /etc/docker
    echo -e "${COLOR_BLUE}docker-ce 修改 配置文件的文件夹 权限${COLOR_RESET}" && sudo chmod o+w /etc/docker
    echo -e "${COLOR_BLUE}docker-ce 创建 配置文件${COLOR_RESET}"
    cat <<EOF >/etc/docker/daemon.json
{
  "registry-mirrors": ["https://hnkfbj7x.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

    echo -e "${COLOR_BLUE}docker-ce 配置文件${COLOR_RESET}" && cat /etc/docker/daemon.json
    echo -e "${COLOR_BLUE}docker-ce 重启${COLOR_RESET}"
    # 需要先停止，在启动，否则在 openkylin 中将存在问题（原因是 openkylin 中原来存在 docker 软件）
    sudo systemctl stop docker.socket
    sudo systemctl stop docker.service
    sudo systemctl restart docker.socket
    sudo systemctl restart docker.service
    echo -e "${COLOR_BLUE}docker-ce 状态${COLOR_RESET}" && sudo systemctl status docker.service --no-pager || true
    echo -e "${COLOR_BLUE}docker-ce 设置开机自启${COLOR_RESET}" && sudo systemctl enable docker.service

    echo -e "${COLOR_BLUE}docker-ce 安装结束${COLOR_RESET}"
  fi
}

# kubernetes 仓库
_kubernetes_repo() {
  # https://developer.aliyun.com/mirror/kubernetes/

  if [[ $kubernetes_repo_skip == true ]]; then
    echo -e "${COLOR_YELLOW}添加 kubernetes 仓库 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}kubernetes 仓库 添加开始${COLOR_RESET}"

    if [[ $ID == anolis || $ID == centos || $ID == uos || $ID = openEuler ]]; then

      cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v$kubernetes_repo_new_version/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v$kubernetes_repo_new_version/rpm/repodata/repomd.xml.key

EOF

    elif [[ $ID == ubuntu || $ID == openkylin ]]; then

      sudo apt-get install -y apt-transport-https

      curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v$kubernetes_repo_new_version/deb/Release.key |
          gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v$kubernetes_repo_new_version/deb/ /" |
          tee /etc/apt/sources.list.d/kubernetes.list

      echo -e "${COLOR_BLUE}kubernetes 仓库 内容：${COLOR_RESET}${COLOR_GREEN}/etc/apt/sources.list.d/kubernetes.list${COLOR_RESET}" && cat /etc/apt/sources.list.d/kubernetes.list

      echo -e "${COLOR_BLUE}更新 kubernetes 仓库源${COLOR_RESET}" && sudo apt-get update
    fi

    echo -e "${COLOR_BLUE}kubernetes 仓库 添加结束${COLOR_RESET}"
  fi
}

# kubernetes 配置
_kubernetes_conf() {
  # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/

  if [[ $kubernetes_conf_skip == true ]]; then
    echo -e "${COLOR_YELLOW}kubernetes 配置 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}kubernetes 配置开始${COLOR_RESET}"

    echo -e "${COLOR_BLUE}kubernetes 配置：${COLOR_RESET}${COLOR_GREEN}/etc/modules-load.d/k8s.conf${COLOR_RESET}"
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    if grep -qi "Microsoft" /proc/version || grep -qi "WSL" /proc/version; then
      echo "Running on WSL"
    else
      echo -e "${COLOR_BLUE}kubernetes 配置：加载 br_netfilter${COLOR_RESET}" && sudo modprobe br_netfilter
      echo -e "${COLOR_BLUE}kubernetes 配置：加载 overlay${COLOR_RESET}" && sudo modprobe overlay
    fi

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

    if grep -qi "Microsoft" /proc/version || grep -qi "WSL" /proc/version; then
      echo "Running on WSL"
    else
      echo -e "${COLOR_BLUE}kubernetes 配置：确认加载 br_netfilter${COLOR_RESET}" && lsmod | grep br_netfilter
      echo -e "${COLOR_BLUE}kubernetes 配置：确认加载 overlay${COLOR_RESET}" && lsmod | grep overlay
    fi

    # https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/
    # 通过运行以下指令确认 net.bridge.bridge-nf-call-iptables、net.bridge.bridge-nf-call-ip6tables 和 net.ipv4.ip_forward 系统变量在你的 sysctl 配置中被设置为 1：
    echo -e "${COLOR_BLUE}kubernetes 配置：修改网络${COLOR_RESET}" && sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

    sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
    sudo sysctl -p /etc/sysctl.conf

    echo -e "${COLOR_BLUE}kubernetes 配置结束${COLOR_RESET}"
  fi
}

# 主机名判断
_hostname() {
  ETC_HOSTNAME=$(cat /etc/hostname)
  CMD_HOSTNAME=$(hostname)
  if [[ $CMD_HOSTNAME =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    if ! [ "$ETC_HOSTNAME" ]; then
      echo -e "${COLOR_BLUE}主机名符合要求${COLOR_RESET}"
    elif [[ "$ETC_HOSTNAME" == "$CMD_HOSTNAME" ]]; then
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

# systemd 安装
_systemd_install() {
  if [[ $ID == centos ]]; then
    local systemd_version=$(rpm -q systemd)
    echo -e "${COLOR_BLUE}systemd 版本 ${COLOR_RESET}${COLOR_GREEN}${systemd_version}${COLOR_RESET}"

    if [[ "$systemd_version" < "$systemd_target_version" ]]; then
      echo -e "${COLOR_BLUE}systemd 版本过低，升级 systemd 开始${COLOR_RESET}"
      sudo yum -y install systemd
      echo -e "${COLOR_BLUE}systemd 版本过低，升级 systemd 结束${COLOR_RESET}"
    else
      echo -e "${COLOR_BLUE}systemd 版本 符合要求，继续安装${COLOR_RESET}"
    fi
  fi
}

# kernel 需求检查
_kernel_required() {
  if [[ $kernel_required_skip == true ]]; then
    echo -e "${COLOR_YELLOW}kernel 需求检查 已被跳过${COLOR_RESET}"
  else
    if [[ $ID == centos ]]; then
      local kernel_version=$(uname -r)
      echo -e "${COLOR_BLUE}kernel 版本 ${COLOR_RESET}${COLOR_GREEN}${kernel_version}${COLOR_RESET}"

      result=$(_compare_version "$kernel_version" "$kernel_target_version") || true
      if [[ $result == 1 ]]; then
        echo -e "${COLOR_RED}kernel 版本低于 ${kernel_target_version} 不符合要求，停止安装${COLOR_RESET}"
        echo -e "${COLOR_RED}升级 kernel 属于敏感操作，并且需要重启系统，因此该脚本不支持自动执行升级 kernel${COLOR_RESET}"
        echo -e "${COLOR_RED}请手动指定以下命令升级 kernel${COLOR_RESET}"
        echo -e "${COLOR_GREEN}yum -y install kernel${COLOR_RESET}"
        echo -e "${COLOR_RED}重启系统，使新内核生效，即可重新执行安装${COLOR_RESET}"
        exit 1
      else
        echo -e "${COLOR_BLUE}kernel 版本 符合要求，继续安装${COLOR_RESET}"
      fi
    fi
  fi
}

# kubernetes 安装
_kubernetes_install() {
  if [[ $kubernetes_install_skip == true ]]; then
    echo -e "${COLOR_YELLOW}kubernetes 安装 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}kubernetes 安装开始${COLOR_RESET}"

    # 主机名判断
    _hostname

    # systemd 安装
    _systemd_install

    if [[ $ID == uos ]]; then
      # UOS 安装 kubernetes 失败时，重试一次
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        sudo yum install -y kubelet-"$kubernetes_version"-0 kubeadm-"$kubernetes_version"-0 kubectl-"$kubernetes_version"-0 --disableexcludes=kubernetes --nogpgcheck || sudo yum install -y kubelet-"$kubernetes_version"-0 kubeadm-"$kubernetes_version"-0 kubectl-"$kubernetes_version"-0 --disableexcludes=kubernetes --nogpgcheck
      else
        echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}最新版${COLOR_RESET}"
        sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck || sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
      fi
    elif [[ $ID == anolis || $ID == centos || $ID = openEuler ]]; then
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        sudo yum install -y kubelet-"$kubernetes_version"-0 kubeadm-"$kubernetes_version"-0 kubectl-"$kubernetes_version"-0 --disableexcludes=kubernetes --nogpgcheck
      else
        echo -e "${COLOR_BLUE}kubernetes 安装 ${COLOR_RESET}${COLOR_GREEN}最新版${COLOR_RESET}"
        sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
      fi
    elif [[ $ID == ubuntu || $ID == openkylin ]]; then

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
  fi
}

# kubernetes 拉取镜像
_kubernetes_images_pull() {
  if [[ $kubernetes_images_pull == true ]]; then
    if [ "$kubernetes_version" ]; then
      echo -e "${COLOR_BLUE}kubernetes 拉取 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}${COLOR_BLUE} 镜像开始${COLOR_RESET}"
      kubeadm config images list --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version"
      kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version"
      echo -e "${COLOR_BLUE}kubernetes 拉取 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}${COLOR_BLUE} 镜像结束${COLOR_RESET}"
    else
      # https://cdn.dl.k8s.io/release/stable-1.txt
      echo -e "${COLOR_BLUE}kubernetes 拉取 ${COLOR_RESET}${COLOR_GREEN}当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}${COLOR_BLUE} 开始${COLOR_RESET}"
      kubeadm config images list --image-repository=registry.aliyuncs.com/google_containers
      kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers
      echo -e "${COLOR_BLUE}kubernetes 拉取 ${COLOR_RESET}${COLOR_GREEN}当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}${COLOR_BLUE} 结束${COLOR_RESET}"
    fi
  fi
}

# kubernetes 初始化 https://kubernetes.io/zh-cn/docs/reference/setup-tools/kubeadm/kubeadm-init/
_kubernetes_init() {
  if [[ $kubernetes_init_skip == true ]]; then
    echo -e "${COLOR_YELLOW}kubernetes 初始化 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}kubernetes 初始化开始${COLOR_RESET}"

    if [[ $kubernetes_init_v ]]; then
      init_v="--v=$kubernetes_init_v"
    fi

    if [[ $apiserver_advertise_address ]]; then
      init_api_address="--apiserver-advertise-address=$apiserver_advertise_address"
    fi

    if [[ $apiserver_bind_port ]]; then
      init_api_port="--apiserver-bind-port=$apiserver_bind_port"
    fi

    if [[ $node_name ]]; then
      init_node_name="--node-name=$node_name"
    fi

    if [[ $service_cidr ]]; then
      init_service_cidr="--service-cidr=$service_cidr"
    fi

    if [[ $pod_network_cidr ]]; then
      init_pod_network_cidr="--pod-network-cidr=$pod_network_cidr"
    fi

    if [[ $availability_vip ]]; then
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 高可用 VIP ${COLOR_RESET}${COLOR_GREEN}${availability_vip}${COLOR_RESET}${COLOR_BLUE} 初始化时使用的镜像版本 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        # 此处的 $init_ 开头的参数不能带引号
        kubeadm init $init_v $init_api_address $init_api_port $init_node_name $init_service_cidr $init_pod_network_cidr --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version" --control-plane-endpoint "$availability_vip:9443" --upload-certs
      else
        # https://cdn.dl.k8s.io/release/stable-1.txt
        echo -e "${COLOR_BLUE}kubernetes 高可用 VIP ${COLOR_RESET}${COLOR_GREEN}${availability_vip}${COLOR_RESET}${COLOR_BLUE} 初始化时使用当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}"
        # 此处的 $init_ 开头的参数不能带引号
        kubeadm init $init_v $init_api_address $init_api_port $init_node_name $init_service_cidr $init_pod_network_cidr --image-repository=registry.aliyuncs.com/google_containers --control-plane-endpoint "$availability_vip:9443" --upload-certs
      fi
    else
      if [ "$kubernetes_version" ]; then
        echo -e "${COLOR_BLUE}kubernetes 初始化时使用的镜像版本 ${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"
        # 此处的 $init_ 开头的参数不能带引号
        kubeadm init $init_v $init_api_address $init_api_port $init_node_name $init_service_cidr $init_pod_network_cidr --image-repository=registry.aliyuncs.com/google_containers --kubernetes-version=v"$kubernetes_version"
      else
        # https://cdn.dl.k8s.io/release/stable-1.txt
        echo -e "${COLOR_BLUE}kubernetes 初始化时使用当前次级版本最新镜像（自动联网获取版本号）${COLOR_RESET}"
        # 此处的 $init_ 开头的参数不能带引号
        kubeadm init $init_v $init_api_address $init_api_port $init_node_name $init_service_cidr $init_pod_network_cidr --image-repository=registry.aliyuncs.com/google_containers
      fi
    fi

    echo -e "${COLOR_BLUE}在环境变量文件 ${COLOR_RESET}${COLOR_GREEN}/etc/profile${COLOR_RESET} 中配置 ${COLOR_GREEN}KUBECONFIG=/etc/kubernetes/admin.conf${COLOR_RESET}"
    sudo bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/profile"
    echo -e "${COLOR_BLUE}授权 ${COLOR_RESET}${COLOR_GREEN}/etc/kubernetes/admin.conf${COLOR_RESET} 文件其他人能访问${COLOR_RESET}"
    sudo chmod a+r /etc/kubernetes/admin.conf
    echo -e "${COLOR_BLUE}刷新环境变量${COLOR_RESET}"
    source /etc/profile
    . /etc/os-release

    # https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-linux/#optional-kubectl-configurations

    echo -e "${COLOR_BLUE}启动 kubectl 自动补全功能${COLOR_RESET}"

    if [[ $ID == anolis || $ID == centos || $ID == uos || $ID = openEuler ]]; then
      echo -e "${COLOR_BLUE}bash-completion 安装开始${COLOR_RESET}"
      sudo yum -y install bash-completion
      source /etc/profile
      . /etc/os-release
      echo -e "${COLOR_BLUE}bash-completion 安装完成${COLOR_RESET}"

      source <(kubectl completion bash)
      echo "source <(kubectl completion bash)" >> ~/.bashrc
      source ~/.bashrc
    else
      sudo mkdir -p /etc/bash_completion.d
      kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null
      sudo chmod a+r /etc/bash_completion.d/kubectl
    fi

    echo -e "${COLOR_BLUE}源引 ~/.bashrc 文件${COLOR_RESET}"
    source ~/.bashrc
    . /etc/os-release

    echo -e "${COLOR_BLUE}显示群集信息${COLOR_RESET}" && kubectl cluster-info
    echo -e "${COLOR_BLUE}显示 node 信息${COLOR_RESET}" && kubectl get nodes -o wide
    echo -e "${COLOR_BLUE}显示 pod 信息${COLOR_RESET}" && kubectl get pod --all-namespaces -o wide
    echo -e "${COLOR_BLUE}显示 svc 信息${COLOR_RESET}" && kubectl get svc --all-namespaces -o wide

    echo -e "${COLOR_BLUE}kubernetes 初始化结束${COLOR_RESET}"

    echo ""
  fi
}

# kubernetes 去污
_kubernetes_taint() {
  if [[ $kubernetes_taint == true ]]; then
    echo -e "${COLOR_BLUE}kubernetes 去污开始${COLOR_RESET}"

    source /etc/profile

    echo -e "${COLOR_BLUE}kubernetes 查看污点${COLOR_RESET}"
    kubectl get no -o yaml | grep taint -A 10 || echo -e "${COLOR_YELLOW}kubernetes 查看污点 失败${COLOR_RESET}"

    echo -e "${COLOR_BLUE}kubernetes 去污${COLOR_RESET}"
    kubectl taint nodes --all node-role.kubernetes.io/control-plane- || echo -e "${COLOR_YELLOW}kubernetes 去污 失败${COLOR_RESET}"

    echo -e "${COLOR_BLUE}kubernetes 查看污点${COLOR_RESET}"
    kubectl get no -o yaml | grep taint -A 10 || echo -e "${COLOR_YELLOW}kubernetes 查看污点 失败${COLOR_RESET}"

    echo -e "${COLOR_BLUE}kubernetes 查看节点${COLOR_RESET}"
    kubectl get nodes -o wide

    echo -e "${COLOR_BLUE}kubernetes 查看所有 pod${COLOR_RESET}"
    kubectl get pod --all-namespaces -o wide

    echo -e "${COLOR_BLUE}kubernetes 去污结束${COLOR_RESET}"
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

# kubernetes 网络插件 calico 初始化
function _calico_init() {
  if [[ $calico_init_skip == true ]]; then
    echo -e "${COLOR_YELLOW}calico 初始化 已被跳过${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 初始化开始${COLOR_RESET}"

    if [[ $calico_manifests_mirror ]]; then
      echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 使用自定义配置文件：${COLOR_RESET}${COLOR_GREEN}${calico_manifests_mirror}${COLOR_RESET}"
      curl -o calico.yaml "$calico_manifests_mirror"
    else
      echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 使用版本：${COLOR_RESET}${COLOR_GREEN}${calico_version}${COLOR_RESET}"
      curl -o calico.yaml https://jihulab.com/xuxiaowei-jihu/mirrors-github/projectcalico/calico/-/raw/v"$calico_version"/manifests/calico.yaml
    fi

    # 网卡
    _interface_name

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 使用网卡：${COLOR_RESET}${COLOR_GREEN}${interface_name}${COLOR_RESET}"

    sed -i '/k8s,bgp/a \            - name: IP_AUTODETECTION_METHOD\n              value: "interface=INTERFACE_NAME"' calico.yaml
    sed -i "s#INTERFACE_NAME#$interface_name#g" calico.yaml

    if [ "$calico_mirrors" ]; then
      echo -e "${COLOR_BLUE}接收到参数 calico-mirrors：${COLOR_RESET}${COLOR_GREEN}${calico_mirrors}${COLOR_RESET}"
      sed -i "s#docker\.io#$calico_mirrors#g" calico.yaml
    fi

    kubectl apply -f calico.yaml
    kubectl get nodes -o wide
    kubectl get pod,svc --all-namespaces -o wide

    echo -e "${COLOR_BLUE}kubernetes 网络插件 calico 初始化结束${COLOR_RESET}"

    echo ""

    echo -e "${COLOR_BLUE}SSH 重新连接或者执行 source /etc/profile && source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubectl get pod --all-namespaces -o wide${COLOR_RESET}"

    echo ""
  fi
}

# Metrics Server 插件
_metrics_server_install() {
  if [ "$metrics_server_install" == true ]; then
    echo -e "${COLOR_BLUE}Metrics Server 插件 安装开始${COLOR_RESET}"

    # 自定义镜像：优先级高于 metrics_server_version、metrics_server_availability
    if [ "$metrics_server_manifests_mirror" ]; then
      echo -e "${COLOR_BLUE}Metrics Server 插件 使用自定义配置文件：${COLOR_RESET}${COLOR_GREEN}${metrics_server_manifests_mirror}${COLOR_RESET}"
      curl -o components.yaml "$metrics_server_manifests_mirror"
    else

      # 自定义高可用
      if [ "$metrics_server_availability" == true ]; then
        echo -e "${COLOR_BLUE}Metrics Server 插件 下载 ${COLOR_RESET}${COLOR_GREEN}高可用${COLOR_RESET}${COLOR_BLUE} 配置文件${COLOR_RESET}"
        curl -o components.yaml "https://github.com/kubernetes-sigs/metrics-server/releases/download/v$metrics_server_version/high-availability-1.21+.yaml"
      else
        echo -e "${COLOR_BLUE}Metrics Server 插件 下载配置文件${COLOR_RESET}"
        curl -o components.yaml "https://github.com/kubernetes-sigs/metrics-server/releases/download/v$metrics_server_version/components.yaml"
      fi

    fi

    # 不验证证书
    echo -e "${COLOR_BLUE}Metrics Server 插件 不验证证书${COLOR_RESET}"
    sed -i '/- args:/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

    # 使用 docker hub 镜像
    echo -e "${COLOR_BLUE}Metrics Server 插件 设置镜像：${COLOR_RESET}${COLOR_GREEN}${metrics_server_mirror}${COLOR_RESET}"
    sed -i "s|registry\.k8s\.io/metrics-server/metrics-server|$metrics_server_mirror|g" components.yaml

    # 应用
    echo -e "${COLOR_BLUE}Metrics Server 插件 应用配置${COLOR_RESET}"
    kubectl apply -f components.yaml

    # 查看 所有 pod
    echo -e "${COLOR_BLUE}查看所有 pod${COLOR_RESET}"
    kubectl get pod,svc --all-namespaces -o wide

    echo -e "${COLOR_BLUE}Metrics Server 插件 安装完成${COLOR_RESET}"
  fi
}

# Ingress Nginx 安装
_ingress_nginx_install() {
  if [ "$ingress_nginx_install" == true ]; then
    echo -e "${COLOR_BLUE}Ingress Nginx 插件 安装开始${COLOR_RESET}"

    echo -e "${COLOR_BLUE}Ingress Nginx 插件 下载配置文件${COLOR_RESET}"
    curl -o deploy.yaml https://jihulab.com/xuxiaowei-jihu/mirrors-github/kubernetes/ingress-nginx/-/raw/controller-v$ingress_nginx_version/deploy/static/provider/cloud/deploy.yaml

    echo -e "${COLOR_BLUE}Ingress Nginx 插件 修改镜像${COLOR_RESET}"
    sudo sed -i 's/@.*$//' deploy.yaml
    sudo sed -i "s#registry.k8s.io/ingress-nginx/controller#$ingress_nginx_controller_mirror#g" deploy.yaml
    sudo sed -i "s#registry.k8s.io/ingress-nginx/kube-webhook-certgen#$ingress_nginx_kube_webhook_certgen_mirror#g" deploy.yaml

    echo -e "${COLOR_BLUE}k8s 配置 Ingress Nginx${COLOR_RESET}"
    sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f deploy.yaml

    echo -e "${COLOR_BLUE}Ingress Nginx 插件 安装结束${COLOR_RESET}"
  fi
}

_ingress_nginx_host_network() {
  if [ "$ingress_nginx_host_network" == true ]; then
    echo -e "${COLOR_BLUE}Ingress Nginx 插件 配置 hostNetwork 开始${COLOR_RESET}"
    sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf -n ingress-nginx patch deployment ingress-nginx-controller --patch '{"spec": {"template": {"spec": {"hostNetwork": true}}}}'
    echo -e "${COLOR_BLUE}Ingress Nginx 插件 配置 hostNetwork 结束${COLOR_RESET}"
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
  echo -e "${COLOR_BLUE}更新 ${ID} 仓库源${COLOR_RESET}" && sudo apt-get update
elif [[ $ID == openkylin ]]; then
  echo -e "${COLOR_BLUE}更新 ${ID} 仓库源${COLOR_RESET}" && sudo apt-get update
  echo -e "${COLOR_BLUE}安装 curl${COLOR_RESET}" && sudo apt install curl
elif [[ $ID == uos ]]; then
  echo ""
elif [[ $ID == openEuler ]]; then
  echo ""
else
  echo -e "${COLOR_RED}不支持 ${ID} 系统${COLOR_RESET}"
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in

  kubernetes-version=* | -kubernetes-version=* | --kubernetes-version=*)
    kubernetes_version="${1#*=}"

    echo -e "${COLOR_BLUE}支持安装的 kubernetes 版本号：${COLOR_RESET}${COLOR_GREEN}${lower_major}.${lower_minor}~${upper_major}.${upper_minor}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubernetes 指定版本号：${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"

    _check_kubernetes_version_range "$kubernetes_version"
    ;;

  kernel-required-skip | -kernel-required-skip | --kernel-required-skip)
    kernel_required_skip=true
    ;;

  apiserver-advertise-address=* | -apiserver-advertise-address=* | --apiserver-advertise-address=*)
    apiserver_advertise_address="${1#*=}"
    ;;

  apiserver-bind-port=* | -apiserver-bind-port=* | --apiserver-bind-port=*)
    apiserver_bind_port="${1#*=}"
    ;;

  node-name=* | -node-name=* | --node-name=*)
    node_name="${1#*=}"
    ;;

  service-cidr=* | -service-cidr=* | --service-cidr=*)
    service_cidr="${1#*=}"
    ;;

  pod-network-cidr=* | -pod-network-cidr=* | --pod-network-cidr=*)
    pod_network_cidr="${1#*=}"
    ;;

  calico-version=* | -calico-version=* | --calico-version=*)
    calico_version="${1#*=}"
    ;;

  calico-init-skip | -calico-init-skip | --calico-init-skip)
    calico_init_skip=true
    ;;

  calico-manifests-mirror=* | -calico-manifests-mirror=* | --calico-manifests-mirror=*)
    calico_manifests_mirror="${1#*=}"
    ;;

  ntp-install-skip | -ntp-install-skip | --ntp-install-skip)
    ntp_install_skip=true
    ;;

  ca-certificates-install-skip | -ca-certificates-install-skip | --ca-certificates-install-skip)
    ca_certificates_install_skip=true
    ;;

  bash-completion-install-skip | -bash-completion-install-skip | --bash-completion-install-skip)
    bash_completion_install_skip=true
    ;;

  selinux-permissive-skip | -selinux-permissive-skip | --selinux-permissive-skip)
    selinux_permissive_skip=true
    ;;

  firewalld-stop-skip | -firewalld-stop-skip | --firewalld-stop-skip)
    firewalld_stop_skip=true
    ;;

  swap-off-skip | -swap-off-skip | --swap-off-skip)
    swap_off_skip=true
    ;;

  docker-repo-type=* | -docker-repo-type=* | --docker-repo-type=*)
    docker_repo_type="${1#*=}"
    ;;

  docker-repo-skip | -docker-repo-skip | --docker-repo-skip)
    docker_repo_skip=true
    ;;

  containerd-install-skip | -containerd-install-skip | --containerd-install-skip)
    containerd_install_skip=true
    ;;

  docker-ce-install-skip | -docker-ce-install-skip | --docker-ce-install-skip)
    docker_ce_install_skip=true
    ;;

  kubernetes-init-v=* | -kubernetes-init-v=* | --kubernetes-init-v=*)
    kubernetes_init_v="${1#*=}"
    ;;

  kubernetes-repo-skip | -kubernetes-repo-skip | --kubernetes-repo-skip)
    kubernetes_repo_skip=true
    ;;

  kubernetes-repo-new-version=* | -kubernetes-repo-new-version=* | --kubernetes-repo-new-version=*)
    kubernetes_repo_new_version="${1#*=}"
    ;;

  kubernetes-conf-skip | -kubernetes-conf-skip | --kubernetes-conf-skip)
    kubernetes_conf_skip=true
    ;;

  kubernetes-install-skip | -kubernetes-install-skip | --kubernetes-install-skip)
    kubernetes_install_skip=true
    ;;

  kubernetes-images-pull | -kubernetes-images-pull | --kubernetes-images-pull)
    kubernetes_images_pull=true
    ;;

  kubernetes-init-skip | -kubernetes-init-skip | --kubernetes-init-skip)
    kubernetes_init_skip=true
    ;;

  kubernetes-taint | -kubernetes-taint | --kubernetes-taint)
    kubernetes_taint=true
    ;;

  metrics-server-install | -metrics-server-install | --metrics-server-install)
    metrics_server_install=true
    ;;

  metrics-server-version=* | -metrics-server-version=* | --metrics-server-version=*)
    metrics_server_version="${1#*=}"
    echo -e "${COLOR_BLUE}Metrics Server 插件 自定义版本号：${COLOR_RESET}${COLOR_GREEN}${metrics_server_version}${COLOR_RESET}"
    ;;

  metrics-server-availability | -metrics-server-availability | --metrics-server-availability)
    metrics_server_availability=true
    ;;

  metrics-server-manifests-mirror=* | -metrics-server-manifests-mirror=* | --metrics-server-manifests-mirror=*)
    metrics_server_manifests_mirror="${1#*=}"
    ;;

  metrics-server-mirror=* | -metrics-server-mirror=* | --metrics-server-mirror=*)
    metrics_server_mirror="${1#*=}"
    ;;

  ingress-nginx-install | -ingress-nginx-install | --ingress-nginx-install)
    ingress_nginx_install=true
    ;;

  ingress-nginx-version=* | -ingress-nginx-version=* | --ingress-nginx-version=*)
    ingress_nginx_version="${1#*=}"
    echo -e "${COLOR_BLUE}Ingress Nginx 插件 自定义版本号：${COLOR_RESET}${COLOR_GREEN}${ingress_nginx_version}${COLOR_RESET}"
    ;;

  ingress-nginx-controller-mirror=* | -ingress-nginx-controller-mirror=* | --ingress-nginx-controller-mirror=*)
    ingress_nginx_controller_mirror="${1#*=}"
    ;;

  ingress-nginx-kube-webhook-certgen-mirror=* | -ingress-nginx-kube-webhook-certgen-mirror=* | --ingress-nginx-kube-webhook-certgen-mirror=*)
    ingress_nginx_kube_webhook_certgen_mirror="${1#*=}"
    ;;

  ingress-nginx-host-network | -ingress-nginx-host-network | --ingress-nginx-host-network)
    ingress_nginx_host_network=true
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

  uos-slirp4netns-mirror=* | -uos-slirp4netns-mirror=* | --uos-slirp4netns-mirror=*)
    uos_slirp4netns_mirror="${1#*=}"
    ;;

  uos-fuse-overlayfs-mirror=* | -uos-fuse-overlayfs-mirror=* | --uos-fuse-overlayfs-mirror=*)
    uos_fuse_overlayfs_mirror="${1#*=}"
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

# ca-certificates 安装
_ca_certificates_install

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

# docker-ce 安装
_docker_ce_install

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

# kernel 需求检查
_kernel_required

# kubernetes 仓库
_kubernetes_repo

# kubernetes 配置
_kubernetes_conf

# kubernetes 安装
_kubernetes_install

# kubernetes 拉取镜像
_kubernetes_images_pull

# kubernetes 初始化
_kubernetes_init

# kubernetes 去污
_kubernetes_taint

# kubernetes 网络插件 calico 初始化
_calico_init

# Metrics Server 插件
_metrics_server_install

# Ingress Nginx 安装
_ingress_nginx_install

# Ingress Nginx hostNetwork
_ingress_nginx_host_network

if [[ $kubernetes_init_skip != true ]]; then
  echo ""
  echo -e '\e[5;34mSSH 重新连接或者执行 source /etc/profile && source ~/.bashrc 命令，使配置文件生效，即可执行 kubectl 命令\e[0m'
  echo -e '\e[5;34mkubectl get pod --all-namespaces -o wide\e[0m'
  echo ""
fi
