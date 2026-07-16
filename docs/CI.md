# GitHub Actions CI 가이드

PRD Stage 3 최소 구현: **Terraform fmt/validate/plan** + **BE npm test**.

## 워크플로

| 파일 | 트리거 | 하는 일 |
|------|--------|---------|
| `.github/workflows/be-ci.yml` | `BE/**` 변경, PR/push | `npm ci` + `npm test` |
| `.github/workflows/terraform-ci.yml` | `terraform/**` 변경, PR/push | `fmt -check` → `validate` → (선택) `plan` |

### Terraform job 동작

1. **check (필수)**  
   - AWS 자격 **불필요**  
   - `terraform fmt -check`  
   - `terraform init -backend=false`  
   - `terraform validate`

2. **plan (선택)**  
   - Repository Secrets 에 AWS 키가 있을 때만 실행  
   - 없으면 스킵 (workflow 실패 아님)  
   - `enable_eks=false` 고정으로 비용·시간 최소화  
   - plan 결과 아티팩트 업로드 (7일)

## 필수 설정 (plan 을 돌리려면)

GitHub 저장소 → **Settings → Secrets and variables → Actions → New repository secret**

| Secret 이름 | 값 |
|-------------|-----|
| `AWS_ACCESS_KEY_ID` | IAM 사용자 Access Key |
| `AWS_SECRET_ACCESS_KEY` | Secret Key |

### IAM 권한 (plan 최소)

- 읽기 위주: `ViewOnlyAccess` 또는 커스텀 (EC2/VPC/EKS/IAM Describe 등)  
- **apply 는 CI에서 기본 실행하지 않음** (실수 과금 방지)

리전: `ap-northeast-2`

## 권장 개선 (이후)

1. **OIDC + IAM Role** — 장기 키 제거 (`permissions: id-token: write`)  
2. `terraform plan` 결과를 PR 코멘트로 게시  
3. `main` 보호 브랜치 + Environment approval 후 apply  
4. FE/BE 이미지 빌드 → ECR 푸시 (Stage 4 CD)

## 로컬에서 CI와 동일하게 검사

```bash
# BE
cd BE && npm ci && npm test

# Terraform
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
# plan (로컬 자격 사용)
terraform plan -var='my_ip=203.0.113.10/32' -var='enable_eks=false'
```

## 수동 실행

Actions 탭 → **Terraform CI** 또는 **BE CI** → **Run workflow**
