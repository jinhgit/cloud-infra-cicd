#!/usr/bin/env bash
# 유료 AWS 리소스 apply — 사용자 명시 확인 후에만 실행
# AI/자동화: 사용자 채팅 승인 없이 이 스크립트를 실행하지 말 것
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/terraform"

RED='\033[0;31m'
YEL='\033[1;33m'
NC='\033[0m'

echo -e "${RED}==============================================${NC}"
echo -e "${RED}  유료 AWS 리소스 생성 (과금 발생 가능)${NC}"
echo -e "${RED}==============================================${NC}"
echo ""
echo "다음이 포함될 수 있습니다:"
echo "  - NAT Gateway (시간당 요금, 가장 큼)"
echo "  - EKS 컨트롤 플레인 / 노드 EC2"
echo "  - Bastion EC2 / ALB / ECR"
echo ""
echo "무료 개발만 하려면: Ctrl+C 후 ./scripts/dev-free.sh"
echo ""

# 비대화형: 사용자가 환경변수로만 승인 (채팅에서 명시한 경우 에이전트가 사용자 지시 후 설정)
if [[ "${CONFIRM_PAID_AWS:-}" == "YES_I_ACCEPT_AWS_CHARGES" ]]; then
  echo "[env] CONFIRM_PAID_AWS 확인됨 — 계속합니다."
else
  if [[ ! -t 0 ]]; then
    echo -e "${RED}오류: 대화형이 아닙니다. 유료 apply 를 자동 실행할 수 없습니다.${NC}"
    echo "사용자 승인 후: CONFIRM_PAID_AWS=YES_I_ACCEPT_AWS_CHARGES $0"
    exit 1
  fi
  echo -e "${YEL}과금에 동의하고 apply 하려면 아래를 정확히 입력하세요:${NC}"
  echo "  YES_I_ACCEPT_AWS_CHARGES"
  read -r -p "> " ans
  if [[ "$ans" != "YES_I_ACCEPT_AWS_CHARGES" ]]; then
    echo "취소되었습니다. 과금 apply 하지 않습니다."
    exit 1
  fi
fi

echo ""
echo "terraform.tfvars 에 유료 플래그가 켜져 있는지 확인하세요."
echo "  acknowledge_paid_aws = true"
echo "  nat_gateway_count    = 1 또는 2"
echo "  enable_eks / enable_bastion 필요 시 true"
echo ""

export TF_VAR_acknowledge_paid_aws=true
export TF_VAR_confirm_paid_apply=YES_I_ACCEPT_AWS_CHARGES

terraform init -input=false
terraform plan -input=false -out=tfplan-paid
echo ""
if [[ -t 0 ]] && [[ "${CONFIRM_PAID_AWS:-}" != "YES_I_ACCEPT_AWS_CHARGES" ]]; then
  read -r -p "위 plan 대로 apply 할까요? (yes 입력) > " ans2
  if [[ "$ans2" != "yes" ]]; then
    echo "apply 취소."
    rm -f tfplan-paid
    exit 1
  fi
fi

terraform apply -input=false tfplan-paid
echo ""
echo "완료. 데모 끝나면 즉시: ./scripts/terraform-destroy-paid.sh"
