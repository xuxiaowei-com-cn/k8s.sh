#!/bin/bash
#
# 作者：徐晓伟 xuxiaowei@xuxiaowei.com.cn
# 使用：sudo sh install.sh
# 仓库：https://jihulab.com/xuxiaowei-com-cn/k8s.sh
#

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
  if [[ hostname =~ ^[A-Za-z0-9\.\-]+$ ]]; then
    if [ $(cat /etc/hostname) == $(hostname) ]; then
      echo "主机名符合要求"
    else
      echo "主机名符合要求，但是配置文件与主机名不同，重启后可能造成 k8s 无法正常运行。"
      echo "由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请将配置文件 /etc/hostname 中的主机名与命令 hostname 修改成一致的名称。"
      echo "hostname 是临时主机名，重启后使用 /etc/hostname 文件中的主机名。"
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

# 系统判断
osName

# 主机名判断
hostName

# 网卡选择
interfaceName

# 安装 wget
sudo yum -y install wget

echo '安装中'
