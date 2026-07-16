# 에이전트 / 자동화 규칙 (이 저장소)

## 과금(유료 AWS) — 사용자 확인 필수

다음 작업은 **사용자가 채팅에서 명시적으로 승인한 뒤에만** 수행한다.

| 작업 | 예 |
|------|-----|
| 유료 리소스 생성 | `terraform apply` (NAT/EKS/Bastion/ECR 등) |
| 유료 플래그 켜기 | `acknowledge_paid_aws=true`, `enable_eks=true`, `nat_gateway_count>0` 등 |
| `confirm_paid_apply` 설정 | `YES_I_ACCEPT_AWS_CHARGES` 문자열 주입 |
| 유료 apply 스크립트 | `./scripts/terraform-apply-paid.sh` |

### 승인으로 인정하는 표현 예

- "유료 apply 해줘", "과금 괜찮으니 apply", "YES_I_ACCEPT_AWS_CHARGES 동의하고 배포"
- "destroy 진행" → **과금 중단**이므로 실행 가능 (가능하면 확인 한 번 더)

### 승인 없이 해도 되는 것 (무료)

- 코드/문서 수정, 커밋·푸시(시크릿 제외)
- `docker compose` / `./scripts/dev-free.sh`
- `npm test`, `terraform fmt` / `validate` / **무료 모드 plan**
- GitHub Actions 워크플로 정의 (CI apply 없음)

### 금지

- 사용자 확인 없이 `terraform apply` 로 NAT/EKS/EC2 생성
- 사용자 확인 없이 `confirm_paid_apply` 또는 `acknowledge_paid_aws=true` 를 tfvars에 넣기
- “편의를 위해” 유료 리소스를 백그라운드로 올리기

## 기본 경로

- 개발: `./scripts/dev-free.sh`
- 문서: `docs/FREE_MODE.md`
