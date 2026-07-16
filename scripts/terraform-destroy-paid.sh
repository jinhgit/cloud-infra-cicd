#!/usr/bin/env bash
# 유료 리소스 포함 destroy — 과금 중단용 (권장)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/terraform"

echo "=============================================="
echo "  terraform destroy (과금 리소스 제거)"
echo "=============================================="
echo "NAT / EKS / EC2 / ALB 등이 삭제됩니다."
echo ""

if [[ "${CONFIRM_DESTROY:-}" == "yes" ]]; then
  echo "[env] CONFIRM_DESTROY=yes"
elif [[ -t 0 ]]; then
  read -r -p "destroy 실행할까요? (yes 입력) > " ans
  if [[ "$ans" != "yes" ]]; then
    echo "취소."
    exit 1
  fi
else
  echo "비대화형: CONFIRM_DESTROY=yes $0 로 실행하세요."
  exit 1
fi

# destroy 는 과금 중단이므로 confirm 문구 없이도 동작해야 함.
# 단 paid 플래그가 tfvars 에 있어도 destroy 가능.
export TF_VAR_confirm_paid_apply="${TF_VAR_confirm_paid_apply:-YES_I_ACCEPT_AWS_CHARGES}"
export TF_VAR_acknowledge_paid_aws="${TF_VAR_acknowledge_paid_aws:-true}"

terraform destroy -input=false -auto-approve
echo "Destroy 완료. 잔존 확인: ./scripts/verify-lab.sh"
