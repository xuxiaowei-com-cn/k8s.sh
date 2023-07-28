#!/bin/bash

#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：chmod +x install.sh && sudo ./install.sh
# 仓库：https://jihulab.com/xuxiaowei-com-cn/k8s.sh
# 版本：SNAPSHOT/0.2.0
#

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

# 一旦有命令返回非零值，立即退出脚本
set -e

# 高可用主节点地址
availability_master_array=()

# 高可用 haproxy 用户名
availability_haproxy_username=admin
# 高可用 haproxy 密码
availability_haproxy_password=password

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
      sudo yum -y install iproute
    elif [[ $ID == ubuntu ]]; then
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
    echo -e "${COLOR_BLUE}NTP 开始安装${COLOR_RESET}"

    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl
    echo -e "${COLOR_BLUE}时区设置为亚洲/上海${COLOR_RESET}" && sudo timedatectl set-timezone Asia/Shanghai
    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl

    local ntp_conf="/etc/ntp.conf"
    local backup_file="${ntp_conf}.$(date +%Y%m%d%H%M%S)"

    if [[ $ID == anolis || $ID == centos ]]; then

      if [[ $VERSION == 7* ]]; then
        sudo yum -y install ntpdate && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

        if [ -f "$ntp_conf" ]; then
          cp "$ntp_conf" "$backup_file"
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 已备份为 ${COLOR_RESET}${COLOR_GREEN}${backup_file}${COLOR_RESET}"
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
        local backup_file="${ntp_conf}.$(date +%Y%m%d%H%M%S)"

        sudo yum -y install chrony && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

        if [ -f "$ntp_conf" ]; then
          cp "$ntp_conf" "$backup_file"
          echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 已备份为 ${COLOR_RESET}${COLOR_GREEN}${backup_file}${COLOR_RESET}"
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
      sudo apt-get -y install ntp && echo -e "${COLOR_BLUE}NTP 安装成功${COLOR_RESET}"

      if [ -f "$ntp_conf" ]; then
        sudo cp "$ntp_conf" "$backup_file"
        echo -e "${COLOR_BLUE}NTP 旧配置文件 ${ntp_conf} 已备份为 ${COLOR_RESET}${COLOR_GREEN}${backup_file}${COLOR_RESET}"
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
    fi

    echo -e "${COLOR_BLUE}查看当前时区/时间${COLOR_RESET}" && timedatectl

    echo -e "${COLOR_BLUE}NTP 结束安装${COLOR_RESET}"
  fi
}

# bash-completion 安装
_bash_completion_install() {
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}bash-completion 开始安装${COLOR_RESET}"
    sudo yum -y install bash-completion
    source /etc/profile
    echo -e "${COLOR_BLUE}bash-completion 安装完成${COLOR_RESET}"
  fi
}

# 关闭 selinux
_selinux_permissive() {
  if [[ $ID == anolis || $ID == centos ]]; then
    echo -e "${COLOR_BLUE}selinux 当前状态${COLOR_RESET}" && getenforce
    echo -e "${COLOR_BLUE}selinux 配置文件${COLOR_RESET}" && cat /etc/selinux/config
    echo -e "${COLOR_BLUE}selinux 当前禁用${COLOR_RESET}" && sudo setenforce 0
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

# 高可用 haproxy 安装
_availability_haproxy_install() {

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
    haproxytech/haproxy-debian:2.8
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
  if [[ $VERSION != 20* ]]; then
    echo -e "${COLOR_RED}不支持 ${VERSION} 版本的 ${ID}${COLOR_RESET}"
    exit 1
  fi

  sudo apt-get update
else
  echo -e "${COLOR_RED}不支持 ${ID} 系统${COLOR_RESET}"
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in

  kubernetes_version=*)
    kubernetes_version="${1#*=}"

    echo -e "${COLOR_BLUE}支持安装的 kubernetes 版本号：${COLOR_RESET}${COLOR_GREEN}${lower_major}.${lower_minor}~${upper_major}.${upper_minor}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}kubernetes 指定版本号：${COLOR_RESET}${COLOR_GREEN}${kubernetes_version}${COLOR_RESET}"

    _check_kubernetes_version_range "$kubernetes_version"
    ;;

  ntp_disabled)
    ntp_disabled=true
    ;;

  interface_name=*)
    interface_name="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 指定网卡名：${COLOR_RESET}${COLOR_GREEN}${interface_name}${COLOR_RESET}"

    _check_interface_name "$interface_name"
    ;;

  availability_vip=*)
    availability_vip="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 VIP：${COLOR_RESET}${COLOR_GREEN}${availability_vip}${COLOR_RESET}"

    _check_availability_vip "$availability_vip"
    ;;

  availability_vip_install)
    availability_vip_install=true
    ;;

  availability_vip_no=*)
    availability_vip_no="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 编号：${COLOR_RESET}${COLOR_GREEN}${availability_vip_no}${COLOR_RESET}"

    _check_availability_vip_no "$availability_vip_no"
    ;;

  availability_master=*)
    availability_master="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用主节点地址$((${#availability_master_array[@]} + 1))：${COLOR_RESET}${COLOR_GREEN}${availability_master}${COLOR_RESET}"

    _check_availability_master "$availability_master"
    ;;

  availability_haproxy_username=*)
    availability_haproxy_username="${1#*=}"
    echo -e "${COLOR_BLUE}kubernetes 高可用 haproxy 指定用户名：${COLOR_RESET}${COLOR_GREEN}${availability_haproxy_username}${COLOR_RESET}"

    ;;

  availability_haproxy_password=*)
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

# 高可用 VIP 安装
if [[ $availability_vip_install == true ]]; then
  echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 开始安装${COLOR_RESET}"

  if ! [[ $availability_vip ]]; then
    echo -e "${COLOR_RED}高可用 VIP 不存在，退出程序${COLOR_RESET}"
    exit 1
  fi

  if ! [[ $availability_vip_no ]]; then
    echo -e "${COLOR_RED}VIP 编号 不存在，退出程序${COLOR_RESET}"
    exit 1
  fi

  # 遍历数组
  for master in "${availability_master_array[@]}"; do
    echo "$master"
  done

  echo -e "${COLOR_BLUE}kubernetes 高可用 VIP 结束安装${COLOR_RESET}"
  exit 0
fi
