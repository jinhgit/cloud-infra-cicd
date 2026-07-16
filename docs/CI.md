# GitHub Actions CI 가이드

## 워크플로 목록

| 파일 | 하는 일 | 과금 |
|------|---------|------|
| `be-ci.yml` | `npm test` | 없음 |
| `docker-build.yml` | FE/BE **linux/amd64 빌드만** (푸시 없음) | 없음 |
| `integration.yml` | Compose 기동 후 curl | 없음 |
| `terraform-ci.yml` | fmt/validate + plan + **PR 코멘트** | plan 시 AWS API 호출만 |

**CI에서 terraform apply / ECR push 하지 않음.**

---

## AWS 인증 (plan)

### A) Access Key (현재 동작 가능)

Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### B) OIDC (권장 — 장기 키 제거)

1. AWS IAM에서 GitHub OIDC provider 생성  
   URL: `https://token.actions.githubusercontent.com`  
   Audience: `sts.amazonaws.com`

2. IAM Role 신뢰 정책 예 (저장소에 맞게 수정):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:jinhgit/cloud-infra-cicd:*"
      }
    }
  }]
}
```

3. Role에 plan 용 읽기 권한 (예: `ViewOnlyAccess` 또는 최소 Describe)

4. GitHub Secrets:
   - `AWS_ROLE_ARN` = 위 Role ARN

5. `.github/workflows/terraform-ci.yml` 의  
   `permissions: id-token: write` 주석 해제

워크플로는 `AWS_ROLE_ARN` 이 있으면 **OIDC 우선**, 없으면 Access Key, 둘 다 없으면 plan 스킵.

---

## PR plan 코멘트

PR 에서 terraform 변경 + AWS 자격 있으면  
plan 마지막 약 40줄이 PR 코멘트로 올라갑니다 (free mode 고정).

---

## 로컬 동일 검사

```bash
cd BE && npm ci && npm test
./scripts/integration-test.sh
./scripts/build-images.sh
cd terraform && terraform fmt -check -recursive && terraform init -backend=false && terraform validate
```
