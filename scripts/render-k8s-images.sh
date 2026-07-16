#!/usr/bin/env bash
# k8s 매니페스트의 IMAGE_FE / IMAGE_BE 를 ECR URL 로 치환 → 출력 디렉터리
# 사용:
#   export ECR_BE=... ECR_FE=...   # 또는 terraform output
#   ./scripts/render-k8s-images.sh
#   ./scripts/render-k8s-images.sh /tmp/k8s-out
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/.k8s-render}"
TAG="${IMAGE_TAG:-latest}"

if [[ -z "${ECR_BE:-}" || -z "${ECR_FE:-}" ]]; then
  if ECR_JSON=$(terraform -chdir="$ROOT/terraform" output -json ecr_repository_urls 2>/dev/null); then
    ECR_BE=$(echo "$ECR_JSON" | jq -r '.be // empty')
    ECR_FE=$(echo "$ECR_JSON" | jq -r '.fe // empty')
  fi
fi

if [[ -z "${ECR_BE:-}" || -z "${ECR_FE:-}" || "$ECR_BE" == "null" ]]; then
  echo "ECR_BE / ECR_FE 환경변수를 설정하거나, terraform ecr output 이 필요합니다."
  echo "예: export ECR_BE=123.dkr.ecr.ap-northeast-2.amazonaws.com/cloud-infra-dev-be"
  exit 1
fi

IMG_BE="${ECR_BE}:${TAG}"
IMG_FE="${ECR_FE}:${TAG}"

rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$ROOT/k8s/." "$OUT/"

# macOS/Linux sed
replace() {
  local f="$1"
  if [[ "$(uname)" == Darwin ]]; then
    sed -i '' "s|IMAGE_BE|${IMG_BE}|g" "$f"
    sed -i '' "s|IMAGE_FE|${IMG_FE}|g" "$f"
  else
    sed -i "s|IMAGE_BE|${IMG_BE}|g" "$f"
    sed -i "s|IMAGE_FE|${IMG_FE}|g" "$f"
  fi
}

while IFS= read -r -d '' f; do
  replace "$f"
done < <(find "$OUT" -name '*.yaml' -print0)

if grep -R "IMAGE_FE\|IMAGE_BE" "$OUT" >/dev/null 2>&1; then
  echo "경고: 치환되지 않은 IMAGE_* 가 남아 있습니다."
  grep -Rn "IMAGE_FE\|IMAGE_BE" "$OUT" || true
  exit 1
fi

echo "Rendered → $OUT"
echo "  BE image: $IMG_BE"
echo "  FE image: $IMG_FE"
echo "다음: ./scripts/deploy-k8s.sh $OUT"
