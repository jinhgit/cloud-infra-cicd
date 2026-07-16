# GitHub Actions CI 가이드

## 워크플로 목록

| 파일 | 하는 일 | 과금 |
|------|---------|------|
| `be-ci.yml` | `npm test` | 없음 |
| `docker-build.yml` | FE/BE **linux/amd64 빌드만** (푸시 없음) | 없음 |
| `integration.yml` | Compose 기동 후 curl | 없음 |
| `terraform-ci.yml` | fmt/validate + **OIDC plan (main)** | plan 시 AWS API 호출만 |

**CI에서 terraform apply / ECR push 하지 않음.**

---

## AWS 인증 (plan) — **현재: OIDC**

| 방식 | 상태 |
|------|------|
| **B) OIDC** | **운영 중** — Secret `AWS_ROLE_ARN` · `id-token: write` · main only |
| A) Access Key | GitHub Secrets **삭제 완료** (폴백 코드는 남아 있음) |

### OIDC (적용됨)

1. IAM OIDC Provider: `token.actions.githubusercontent.com` / audience `sts.amazonaws.com`
2. Role: `arn:aws:iam::447170313588:role/gha-cloud-infra-cicd-plan` (`ReadOnlyAccess`)
3. Trust: **main 브랜치만** (구형 sub + ID 포함 sub)
4. Secret: `AWS_ROLE_ARN`
5. Workflow: `permissions.id-token: write` · plan job = main push / `workflow_dispatch`

상세·트러블슈팅(sub 클레임): [OIDC_SETUP.md](OIDC_SETUP.md)

### Access Key (레거시 · 비권장)

과거 폴백용. Secrets 에 키를 다시 넣으면 OIDC 보다 우선하지 않음 — 코드상 **OIDC(`AWS_ROLE_ARN`) 우선**.

---

## Plan 실행 조건

| 이벤트 | fmt/validate | terraform plan (OIDC) |
|--------|--------------|------------------------|
| push `main` (terraform 경로) | ✅ | ✅ |
| `workflow_dispatch` | ✅ | ✅ |
| pull_request | ✅ | ❌ (trust main-only) |

---

## 로컬 동일 검사

```bash
cd BE && npm ci && npm test
./scripts/integration-test.sh
./scripts/build-images.sh
cd terraform && terraform fmt -check -recursive && terraform init -backend=false && terraform validate
# 또는
make check
```
