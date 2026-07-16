# GitHub Actions ↔ AWS OIDC 실전 설정 가이드

**대상 계정 (이 프로젝트 기준)**

| 항목 | 값 |
|------|-----|
| AWS Account ID | `447170313588` |
| 리전 | `ap-northeast-2` |
| GitHub 저장소 | `jinhgit/cloud-infra-cicd` |
| 용도 | Terraform **plan** (apply 없음 · 과금 최소) |
| 기존 방식 | Secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (장기 키) |

이 문서를 따라 하면 **장기 Access Key 없이** CI plan 이 동작합니다.  
(OIDC 설정 자체는 IAM API 호출만 하며, EKS/NAT 생성 없음.)

---

## 0. 목표 구조

```text
GitHub Actions (PR/push)
    │  OIDC JWT (id-token)
    ▼
AWS IAM OIDC Provider
    │  sts:AssumeRoleWithWebIdentity
    ▼
IAM Role (예: gha-cloud-infra-cicd-plan)
    │  읽기 위주 권한
    ▼
terraform plan  (acknowledge_paid_aws=false)
```

워크플로: `.github/workflows/terraform-ci.yml`  
- Secrets에 `AWS_ROLE_ARN` 이 있으면 **OIDC 우선**  
- 없으면 Access Key  
- 둘 다 없으면 plan 스킵 (fmt/validate 만 통과)

---

## 1. GitHub 쪽 준비

### 1-1. 워크플로 권한 (필수)

`terraform-ci.yml` 상단 `permissions` 를 아래처럼 맞춥니다.

```yaml
permissions:
  contents: read
  pull-requests: write
  id-token: write          # OIDC 필수 — 주석 해제
```

> 저장소에 이미 주석 안내가 있습니다. OIDC 쓸 때 **반드시 `id-token: write`**.

### 1-2. 설정할 Secret

| Name | 값 |
|------|-----|
| `AWS_ROLE_ARN` | 아래 2단계에서 만든 Role ARN |

OIDC가 잘 되면 기존 키 Secret은 **삭제**하는 것을 권장합니다.

---

## 2. AWS — OIDC Provider 생성

콘솔: **IAM → Identity providers → Add provider**

| 필드 | 값 |
|------|-----|
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

CLI 예:

```bash
# 썸프린트는 AWS 문서 권장 값 사용 (변경될 수 있음 — 콘솔 자동 가져오기 권장)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

이미 있으면:

```bash
aws iam list-open-id-connect-providers
```

Provider ARN 예:

```text
arn:aws:iam::447170313588:oidc-provider/token.actions.githubusercontent.com
```

---

## 3. AWS — Plan 전용 IAM Role

### 3-1. 신뢰 정책 (Trust policy)

파일 예: `/tmp/gha-trust.json`

> **중요 (2024+ GitHub sub 형식)**  
> 일부 저장소/조직은 `sub` 에 **owner·repo 숫자 ID** 를 넣습니다.  
> CloudTrail 예: `repo:jinhgit@267884150/cloud-infra-cicd@1302872585:ref:refs/heads/main`  
> 구형 `repo:jinhgit/cloud-infra-cicd:*` 만 두면 **AccessDenied** 가 납니다.

### 현재 운영 trust (main 전용 · 적용 완료)

`terraform-ci` 의 plan job 도 **main push / workflow_dispatch** 만 OIDC plan 을 돌립니다.  
PR 은 `fmt` / `validate` 만.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsMainOnly",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::447170313588:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:jinhgit/cloud-infra-cicd:ref:refs/heads/main",
            "repo:jinhgit@*/cloud-infra-cicd@*:ref:refs/heads/main"
          ]
        }
      }
    }
  ]
}
```

- 실제 `sub` 확인: CloudTrail `AssumeRoleWithWebIdentity` 의 `userName` / `principalId`.  
- PR plan 이 필요하면 `...:pull_request` 패턴을 추가하고 workflow `if` 를 완화.

### 3-2. Role 생성

```bash
aws iam create-role \
  --role-name gha-cloud-infra-cicd-plan \
  --assume-role-policy-document file:///tmp/gha-trust.json \
  --description "GitHub Actions Terraform plan (read-mostly)"
```

### 3-3. 권한 (최소~실무 타협)

**빠른 시작 (넓음):**

```bash
aws iam attach-role-policy \
  --role-name gha-cloud-infra-cicd-plan \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

**더 좁히기 (나중에):** EC2/VPC/EKS/IAM `Describe*` / `Get*` / `List*` 만 커스텀 정책.

Role ARN 확인:

```bash
aws iam get-role --role-name gha-cloud-infra-cicd-plan \
  --query 'Role.Arn' --output text
# arn:aws:iam::447170313588:role/gha-cloud-infra-cicd-plan
```

---

## 4. GitHub Secret 등록

```bash
# 로컬에서 (값 노출 주의)
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::447170313588:role/gha-cloud-infra-cicd-plan" \
  --repo jinhgit/cloud-infra-cicd
```

또는 웹: **Settings → Secrets and variables → Actions → New repository secret**

---

## 5. 워크플로 파일 확인

`terraform-ci.yml` 의 plan job 은 대략 다음 순서입니다.

1. `AWS_ROLE_ARN` 있으면 `mode=oidc`  
2. `aws-actions/configure-aws-credentials@v4` + `role-to-assume`  
3. `terraform plan` (free mode 변수 고정)

**수동으로 `id-token: write` 주석 해제** 했는지 확인:

```bash
grep -n "id-token" .github/workflows/terraform-ci.yml
```

없으면 아래를 permissions 에 추가:

```yaml
permissions:
  contents: read
  pull-requests: write
  id-token: write
```

---

## 6. 검증

```bash
# Actions 수동 실행
gh workflow run "Terraform CI" --ref main --repo jinhgit/cloud-infra-cicd
gh run list --workflow="Terraform CI" --limit 3
```

성공 시 plan job 로그에:

- `OIDC role 사용` 또는 AssumeRole 성공  
- `Plan: ...` (무료 모드라 NAT/EKS 0)

### 실패 시

| 증상 | 조치 |
|------|------|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | Trust policy 의 account / sub / aud 확인 |
| `No OpenIDConnect provider` | Provider URL·썸프린트 재생성 |
| plan 스킵 | Secret 이름 `AWS_ROLE_ARN` 오타, 또는 id-token 권한 누락 |
| 권한 부족 | Role 에 ReadOnly 또는 필요 Describe 추가 |

---

## 7. 장기 키 제거 (OIDC 성공 후) — **완료**

| 항목 | 상태 |
|------|------|
| OIDC plan 성공 (main) | ✅ |
| GitHub `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` 삭제 | ✅ |
| Secret `AWS_ROLE_ARN` 만 유지 | ✅ |
| trust main-only | ✅ |
| IAM 사용자(JHM) 로컬 CLI Access Key | **유지** (로컬 Terraform/IAM 관리용 · CI 아님) |

> CI 용 장기 키는 **GitHub Secrets 에서 제거**한 것이 핵심입니다.  
> 콘솔/로컬 AWS CLI 키는 별도 수명 주기로 관리합니다.

---

## 8. 보안 체크리스트

- [x] OIDC Provider 1개 (계정당 공유 가능)  
- [x] Role trust 가 **이 저장소 main** 만 허용  
- [x] Role 이 **plan/읽기** 위주 (`ReadOnlyAccess`)  
- [x] `id-token: write` 설정  
- [x] `AWS_ROLE_ARN` Secret 등록  
- [x] GitHub 장기 키 Secret 삭제  
- [x] apply 는 CI에 없음 + 유료는 `confirm_paid_apply` 가드  

---

## 9. 노션에 옮길 때 요약 블록

```text
제목: GitHub OIDC → AWS plan Role (적용 완료)
계정: 447170313588
Role: gha-cloud-infra-cicd-plan
Repo: jinhgit/cloud-infra-cicd (main only)
Secret: AWS_ROLE_ARN only
권한: ReadOnlyAccess
검증: Terraform CI plan job 초록
완료: Access Key Secret 삭제 · main-only trust
```

---

## 관련 파일

- `.github/workflows/terraform-ci.yml`  
- `docs/CI.md` (개요)  
- `docs/FREE_MODE.md` (유료 apply 금지 원칙)  
- `AGENTS.md`  
