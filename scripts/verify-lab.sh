#!/usr/bin/env bash
# 실습 인프라·앱 상태 빠른 점검
# 사용: 저장소 루트에서 ./scripts/verify-lab.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform"
REGION="${AWS_REGION:-ap-northeast-2}"

green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }
section() { printf '\n======== %s ========\n' "$*"; }

section "1) Terraform"
if [[ ! -d "$TF_DIR" ]]; then
  red "terraform 디렉터리 없음"
  exit 1
fi
cd "$TF_DIR"

if ! command -v terraform >/dev/null; then
  red "terraform CLI 없음"
  exit 1
fi

COUNT="$(terraform state list 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$COUNT" -eq 0 ]]; then
  yellow "state 비어 있음 → AWS 인프라 없음 (destroy 됐거나 미 apply)"
  HAS_TF=0
else
  green "state 리소스 수: $COUNT"
  HAS_TF=1
  terraform output -json > /tmp/tf-out.json 2>/dev/null || true
  if [[ -s /tmp/tf-out.json ]]; then
    python3 - <<'PY'
import json
from pathlib import Path
d = json.loads(Path("/tmp/tf-out.json").read_text())
def v(k, default=None):
    x = d.get(k, {}).get("value", default)
    return x
summary = v("deployment_summary") or {}
print("  status:          ", summary.get("status"))
print("  enable_bastion:  ", summary.get("enable_bastion"))
print("  enable_eks:      ", summary.get("enable_eks"))
print("  nat_gateways:    ", summary.get("nat_gateways"))
print("  vpc_id:          ", v("vpc_id"))
print("  bastion_id:      ", v("bastion_instance_id"))
print("  bastion_public_ip:", v("bastion_public_ip"))
PY
  fi
fi

section "2) AWS (Bastion / NAT)"
if [[ "$HAS_TF" -eq 1 ]] && command -v aws >/dev/null; then
  BID="$(terraform output -raw bastion_instance_id 2>/dev/null || true)"
  if [[ -n "${BID:-}" && "$BID" != "null" ]]; then
    STATE="$(aws ec2 describe-instances --region "$REGION" --instance-ids "$BID" \
      --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo unknown)"
    echo "  bastion state: $STATE"
    PING="$(aws ssm describe-instance-information --region "$REGION" \
      --filters "Key=InstanceIds,Values=$BID" \
      --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || echo None)"
    echo "  SSM PingStatus: $PING"
    if [[ "$STATE" == "running" ]]; then green "  Bastion EC2 OK"; else yellow "  Bastion not running"; fi
    if [[ "$PING" == "Online" ]]; then green "  SSM Online OK"; else yellow "  SSM not Online yet (1~2분 대기 가능)"; fi
  else
    yellow "  Bastion output 없음 (enable_bastion=false?)"
  fi
  NATS="$(aws ec2 describe-nat-gateways --region "$REGION" \
    --filter Name=state,Values=available \
    --query 'length(NatGateways)' --output text 2>/dev/null || echo "?")"
  echo "  available NAT count (account/region): $NATS"
else
  yellow "  AWS CLI 스킵 또는 state 없음"
fi

section "3) 로컬 앱 (Docker Compose)"
if curl -sf --max-time 2 http://127.0.0.1:8080/healthz >/dev/null 2>&1; then
  green "  FE :8080 /healthz OK"
  curl -sf --max-time 2 http://127.0.0.1:8080/health | head -c 120; echo
  curl -sf --max-time 2 http://127.0.0.1:8080/api/hello | head -c 120; echo
  green "  브라우저: http://localhost:8080  및  http://localhost:8080/lab.html"
else
  yellow "  FE :8080 응답 없음 → docker compose up --build 후 확인"
fi
if curl -sf --max-time 2 http://127.0.0.1:3000/health >/dev/null 2>&1; then
  green "  BE :3000 /health OK"
else
  yellow "  BE :3000 응답 없음 (Compose 미기동 시 정상)"
fi

section "4) 다음 액션 힌트"
if [[ "$HAS_TF" -eq 1 ]]; then
  echo "  · SSH:  cd terraform && ssh -i cloud-infra-bastion.pem ec2-user@\$(terraform output -raw bastion_public_ip)"
  echo "  · SSM:  aws ssm start-session --target \$(terraform output -raw bastion_instance_id) --region $REGION"
  echo "  · 앱:   docker compose up --build  →  http://localhost:8080/lab.html"
  echo "  · 종료: cd terraform && terraform destroy"
else
  echo "  · 인프라: cd terraform && terraform apply"
  echo "  · 앱만:   docker compose up --build"
fi
echo
green "검증 스크립트 끝."
