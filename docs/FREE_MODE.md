# 무료 모드 + 유료 작업 시 사용자 확인

이 프로젝트의 **기본은 과금 없음**입니다.  
**유료 AWS 작업은 사용자(본인)가 추가로 확인·동의한 뒤에만** 실행합니다.

---

## 1. 무료로 해도 되는 것 (확인 불필요)

```bash
./scripts/dev-free.sh          # Docker Compose FE/BE
cd BE && npm test
cd terraform && terraform fmt && terraform validate
# plan 은 유료 플래그 전부 off 일 때만
```

| 허용 | 과금 |
|------|------|
| 로컬 Docker · npm test · 문서 · 코드 | 없음 |
| CI: fmt / validate / plan (유료 off) | 없음 |
| `terraform destroy` (리소스 제거) | 과금 **중단** (실행 가능) |

---

## 2. 유료라서 **반드시 확인** 받는 것

| 작업 | 과금 |
|------|------|
| NAT Gateway 생성 | 시간당 (큼) |
| EKS 클러스터/노드 | 시간당 |
| Bastion EC2 | 시간당 |
| ALB / ECR | 시간당·스토리지 |

### 이중 잠금

1. `acknowledge_paid_aws = true`
2. `confirm_paid_apply = "YES_I_ACCEPT_AWS_CHARGES"`  
   → 이 문구는 **본인이 과금에 동의한 뒤에만** 설정

둘 중 하나라도 없으면 유료 리소스 **plan/apply 실패**.

### 권장 실행 방법 (대화형)

```bash
# 1) tfvars 에 데모용 플래그만 준비 (confirm 문구는 스크립트가 처리)
# acknowledge_paid_aws = true
# nat_gateway_count = 2
# enable_eks = true  등

./scripts/terraform-apply-paid.sh
# → YES_I_ACCEPT_AWS_CHARGES 입력 요구
# → plan 확인 후 yes 입력 시에만 apply
```

AI/자동화는 **채팅에서 사용자가 유료 동의를 명시한 경우**에만  
`CONFIRM_PAID_AWS=YES_I_ACCEPT_AWS_CHARGES ./scripts/terraform-apply-paid.sh` 를 실행할 수 있습니다.

### 데모 종료

```bash
./scripts/terraform-destroy-paid.sh
# yes 입력
```

---

## 3. AI 에이전트 규칙

저장소 루트 [AGENTS.md](../AGENTS.md) 참고.

- 유료 apply / 유료 플래그 변경 → **사용자 추가 확인 필수**
- 승인 없이 백그라운드 apply 금지
- destroy(과금 중단)는 사용자가 “destroy 해줘”라고 하면 실행 가능

---

## 4. tfvars 템플릿 (기본 무료)

```hcl
acknowledge_paid_aws = false
confirm_paid_apply   = ""
nat_gateway_count    = 0
enable_bastion       = false
enable_eks           = false
enable_ecr           = false
```

유료 데모 당일만:

```hcl
acknowledge_paid_aws = true
confirm_paid_apply   = "YES_I_ACCEPT_AWS_CHARGES"  # 동의 후
nat_gateway_count    = 2
enable_eks           = true
```

끝나면 전부 되돌리고 `destroy`.
