# 무료 모드 (기본) — 과금 없이 개발하기

이 프로젝트의 **기본 설정은 AWS 유료 리소스를 만들지 않습니다.**

## 원칙

| 해도 됨 (무료) | 하면 과금 |
|----------------|-----------|
| `docker compose` 로 FE/BE | NAT Gateway |
| `npm test` | EKS 컨트롤 플레인 |
| `terraform fmt` / `validate` / `plan` (유료 플래그 OFF) | EC2 Bastion·노드 |
| GitHub Actions CI (분 한도 내) | ALB |
| 코드 작성·문서 | ECR 스토리지(소액) |

## 일상 개발 명령

```bash
# 저장소 루트 — 앱만 (AWS 호출 없음)
./scripts/dev-free.sh

# 또는
docker compose up --build
# http://localhost:8080
# http://localhost:8080/lab.html

# BE 테스트
cd BE && npm test
```

## Terraform 가드

`terraform/cost_guard.tf` + 변수:

```hcl
acknowledge_paid_aws = false   # 기본 — 유료 생성 차단
nat_gateway_count    = 0       # 기본 — NAT 안 만듦
enable_eks           = false
enable_bastion       = false
enable_ecr           = false
```

- `acknowledge_paid_aws=false` 인데 `enable_eks=true` 등이면 **plan 단계에서 실패**합니다.
- NAT/EKS/Bastion 은 `acknowledge_paid_aws=true` 일 때만 생성됩니다.

## AWS 데모가 꼭 필요할 때만 (짧게)

```hcl
# terraform.tfvars — 데모 당일만
acknowledge_paid_aws = true
nat_gateway_count    = 2          # 또는 1 (절약)
enable_bastion       = true       # 필요 시
enable_eks           = true       # 필요 시
```

```bash
terraform apply
# … 데모 …
terraform destroy -auto-approve   # 당일 필수
```

상세: [EKS_E2E_CHECKLIST.md](EKS_E2E_CHECKLIST.md)

## 과금 잔존 확인

```bash
./scripts/verify-lab.sh
# 또는
cd terraform && terraform state list   # 0 이어야 함
aws eks list-clusters --region ap-northeast-2
aws ec2 describe-nat-gateways --region ap-northeast-2 \
  --filter Name=state,Values=available
```

## 요약

**앞으로는 `./scripts/dev-free.sh` 와 CI만 쓰면 이 프로젝트 때문에 AWS 시간 과금이 나지 않습니다.**  
유료 데모는 의식적으로 `acknowledge_paid_aws=true` 를 켠 뒤에만, 끝나면 바로 destroy.
