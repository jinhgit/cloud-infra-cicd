#!/usr/bin/env bash
# FE/BE 이미지 로컬 빌드 (기본 linux/amd64 — EKS 노드 호환)
# 과금 없음 (로컬 Docker만). ECR 푸시는 build-push-images.sh + 유료 동의
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
TAG_BE="${IMAGE_BE:-cloud-infra-be:local}"
TAG_FE="${IMAGE_FE:-cloud-infra-fe:local}"

echo "Building BE → ${TAG_BE} (${PLATFORM})"
docker build --platform "$PLATFORM" \
  --build-arg TARGETPLATFORM="$PLATFORM" \
  --build-arg GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo dev)" \
  --build-arg APP_VERSION="${APP_VERSION:-0.1.0}" \
  -t "$TAG_BE" ./BE

echo "Building FE → ${TAG_FE} (${PLATFORM})"
docker build --platform "$PLATFORM" \
  --build-arg TARGETPLATFORM="$PLATFORM" \
  -t "$TAG_FE" ./FE

echo "OK: $TAG_BE / $TAG_FE"
