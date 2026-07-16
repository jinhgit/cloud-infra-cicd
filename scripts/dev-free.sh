#!/usr/bin/env bash
# 과금 없이 로컬만 개발 — AWS apply 하지 않음
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=========================================="
echo "  FREE MODE — AWS 유료 리소스 생성 안 함"
echo "  FE/BE: docker compose only"
echo "=========================================="

# 실수로 켜진 유료 플래그 경고 (tfvars 있을 때)
if [[ -f terraform/terraform.tfvars ]]; then
  if grep -E '^\s*acknowledge_paid_aws\s*=\s*true' terraform/terraform.tfvars >/dev/null 2>&1; then
    echo "[경고] terraform.tfvars 에 acknowledge_paid_aws=true 가 있습니다."
    echo "       실습이 끝났다면 false 로 바꾸고, AWS 리소스는 destroy 하세요."
  fi
  if grep -E '^\s*enable_eks\s*=\s*true|^\s*enable_bastion\s*=\s*true|^\s*nat_gateway_count\s*=\s*[12]' terraform/terraform.tfvars >/dev/null 2>&1; then
    if ! grep -E '^\s*acknowledge_paid_aws\s*=\s*true' terraform/terraform.tfvars >/dev/null 2>&1; then
      echo "[안내] 유료 플래그가 있어도 acknowledge_paid_aws=false 면 Terraform 이 생성하지 않습니다."
    fi
  fi
fi

echo ""
echo "시작: docker compose up --build"
echo "  UI  http://localhost:8080"
echo "  Lab http://localhost:8080/lab.html"
echo "종료: Ctrl+C 후 docker compose down"
echo ""

exec docker compose up --build
