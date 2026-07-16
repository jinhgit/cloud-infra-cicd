#!/usr/bin/env bash
# 렌더된 매니페스트를 클러스터에 적용 (EKS 기동 중일 때만, 유료 환경)
#   ./scripts/render-k8s-images.sh
#   ./scripts/deploy-k8s.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/.k8s-render}"

if [[ ! -d "$DIR" ]]; then
  echo "디렉터리 없음: $DIR"
  echo "먼저: ./scripts/render-k8s-images.sh"
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "kubectl 이 클러스터에 연결되어 있지 않습니다."
  echo "aws eks update-kubeconfig --region ap-northeast-2 --name cloud-infra-dev-eks"
  exit 1
fi

kubectl apply -f "$DIR/namespace.yaml"
kubectl apply -f "$DIR/be/"
kubectl apply -f "$DIR/fe/"
kubectl apply -f "$DIR/ingress/"

kubectl -n cloud-infra rollout status deploy/be --timeout=180s
kubectl -n cloud-infra rollout status deploy/fe --timeout=180s
kubectl -n cloud-infra get deploy,po,svc,ing -o wide

echo ""
echo "ALB DNS:"
kubectl -n cloud-infra get ingress cloud-infra -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
