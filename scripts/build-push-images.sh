#!/usr/bin/env bash
# ECR 푸시 — 유료 스토리지 소액 가능. 사용자 확인 후에만.
#   CONFIRM_ECR_PUSH=yes ./scripts/build-push-images.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${CONFIRM_ECR_PUSH:-}" != "yes" ]]; then
  if [[ -t 0 ]]; then
    echo "ECR 푸시는 소액 스토리지 과금이 날 수 있습니다."
    read -r -p "계속하려면 yes 입력 > " a
    [[ "$a" == "yes" ]] || { echo "취소"; exit 1; }
  else
    echo "비대화형: CONFIRM_ECR_PUSH=yes $0"
    exit 1
  fi
fi

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

# Terraform output 우선, 없으면 이름 규칙
if ECR_JSON=$(terraform -chdir=terraform output -json ecr_repository_urls 2>/dev/null); then
  ECR_BE=$(echo "$ECR_JSON" | jq -r '.be // empty')
  ECR_FE=$(echo "$ECR_JSON" | jq -r '.fe // empty')
fi
ECR_BE="${ECR_BE:-${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/cloud-infra-dev-be}"
ECR_FE="${ECR_FE:-${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/cloud-infra-dev-fe}"
TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo latest)}"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

export IMAGE_BE="${ECR_BE}:${TAG}"
export IMAGE_FE="${ECR_FE}:${TAG}"
export DOCKER_PLATFORM="$PLATFORM"
export APP_VERSION="${APP_VERSION:-0.1.0}"
./scripts/build-images.sh

docker tag "cloud-infra-be:local" "${ECR_BE}:${TAG}"
docker tag "cloud-infra-be:local" "${ECR_BE}:latest"
docker tag "cloud-infra-fe:local" "${ECR_FE}:${TAG}"
docker tag "cloud-infra-fe:local" "${ECR_FE}:latest"

docker push "${ECR_BE}:${TAG}"
docker push "${ECR_BE}:latest"
docker push "${ECR_FE}:${TAG}"
docker push "${ECR_FE}:latest"

echo "Pushed:"
echo "  ${ECR_BE}:${TAG}"
echo "  ${ECR_FE}:${TAG}"
