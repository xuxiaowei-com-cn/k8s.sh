# 颜色定义
readonly COLOR_BLUE='\033[34m'
readonly COLOR_GREEN='\033[92m'
readonly COLOR_RESET='\033[0m'

echo "$KUBECONFIG"

kubectl get pod --all-namespaces -o wide
kubectl wait --for=condition=Ready --all pods --all-namespaces --timeout=600s
kubectl get pod --all-namespaces -o wide

count=0
max_attempts=100

while [ $count -lt $max_attempts ]; do
  echo -e "${COLOR_BLUE}检查 pod 状态...${COLOR_RESET}"
  kubectl get pod --all-namespaces
  all_running=true

  # 获取所有 pod 的状态
  pod_status=$(kubectl get pod --all-namespaces -o jsonpath='{range .items[*]}{@.status.phase}{"\n"}{end}')

  # 检查每个 pod 的状态是否为 Running
  while read -r status; do
    if [[ $status != "Running" ]]; then
      all_running=false
      break
    fi
  done <<<"$pod_status"

  if $all_running; then
    echo -e "${COLOR_GREEN}所有 pods 全部运行${COLOR_RESET}"
    break
  fi

  count=$((count + 1))

  if [ $count -eq $max_attempts ]; then
    break
  fi

  sleep 10
done
