# 실습 상황 확인 가이드

지금 이 프로젝트는 **단계별로 확인 방법이 다릅니다.**  
현재 AWS에 올라가 있는 것은 보통 **Stage 1 네트워크 + Bastion** 이고, **FE 웹은 AWS에 아직 안 떠 있을 수 있습니다** (EKS Ingress 전).

| 레이어 | 어디서 확인? | 지금 상태 예 |
|--------|----------------|--------------|
| 앱 FE/BE | **로컬** `docker compose` → http://localhost:8080 | 항상 가능 (비용 0) |
| VPC/NAT/SG | AWS 콘솔 · Terraform · `scripts/verify-lab.sh` | apply 했을 때 |
| Bastion | SSH / SSM · 콘솔 EC2 | `enable_bastion=true` 일 때 |
| FE on AWS | EKS + ALB DNS | `enable_eks` + 배포 후 |

---

## 0. 한 줄로 전체 점검 (추천)

저장소 루트에서:

```bash
chmod +x scripts/verify-lab.sh
./scripts/verify-lab.sh
```

스크립트가 출력하는 것:

- Terraform state / `deployment_summary`
- VPC · NAT · Bastion ID/IP
- Bastion instance state, SSM Online 여부
- (선택) 로컬 Compose FE/BE curl

---

## 1. 프론트엔드로 확인 (가장 편함)

### 1-A. 로컬 데모 UI (앱 동작)

```bash
# 저장소 루트
docker compose up --build
```

브라우저:

| URL | 의미 |
|-----|------|
| http://localhost:8080 | 데모 홈 — BE `/health`, `/api/hello` 자동 호출 |
| http://localhost:8080/lab.html | **실습 체크리스트 페이지** (무엇을 확인해야 하는지 안내) |
| http://localhost:3000/health | BE 직접 |

**통과 기준**

- [ ] 홈에서 Backend Health = **OK**
- [ ] GET /api/hello = **OK**
- [ ] lab.html 체크리스트를 보면서 AWS 쪽을 병행 확인

종료:

```bash
docker compose down
```

> 로컬 FE는 **AWS Bastion/VPC를 직접 보여 주지 않습니다.**  
> (브라우저가 AWS 내부 API를 호출하지 않음 — 보안상 정상)  
> AWS 인프라는 아래 2~4절 또는 `verify-lab.sh` 로 확인합니다.

### 1-B. AWS 위 FE (EKS 데모 후)

EKS E2E까지 하면:

```text
http://<ALB_DNS>/
```

절차: [EKS_E2E_CHECKLIST.md](EKS_E2E_CHECKLIST.md)

---

## 2. Terraform으로 확인

```bash
cd terraform

terraform output deployment_summary
terraform output bastion_public_ip
terraform output bastion_instance_id
terraform output bastion_ssh_command
terraform output bastion_ssm_command
terraform output vpc_id
terraform output nat_gateway_ids
terraform state list | head -50
```

| output / 값 | 기대 |
|-------------|------|
| `status` | `stage1+bastion` (Bastion 켠 경우) |
| `nat_gateways` | `2` |
| `bastion_public_ip` | 공인 IP 문자열 |
| `enable_eks` | 지금은 보통 `false` |

state가 비어 있으면 → 이미 `destroy` 됐거나 apply 전입니다.

---

## 3. AWS 콘솔로 확인

리전: **서울 (ap-northeast-2)**

### 3-1. VPC

1. **VPC → Your VPCs**  
   - Name: `cloud-infra-dev-vpc` (또는 `project-env-vpc`)
2. **Subnets**  
   - Public 2, Private Web 2, Private DB 2 → 총 **6**
3. **NAT gateways**  
   - **available** 2개
4. **Route tables**  
   - Private Web: `0.0.0.0/0` → 각 AZ NAT  
   - Private DB: 인터넷 라우트 없음

### 3-2. EC2 (Bastion)

1. **EC2 → Instances**  
   - Name: `cloud-infra-dev-bastion`  
   - State: **running**  
   - Public IPv4 존재  
   - Security group: bastion (SSH 22 ← 내 IP)
2. **보안 그룹 인바운드**  
   - Type SSH, Source `내IP/32` 만 있는지

### 3-3. Systems Manager (SSM)

1. **Systems Manager → Fleet Manager** 또는 **Session Manager**  
2. Bastion 인스턴스가 **Online** 이면 SSM 접속 가능

---

## 4. 터미널로 Bastion 접속 확인

```bash
cd terraform
export BASTION_IP=$(terraform output -raw bastion_public_ip)
export BASTION_ID=$(terraform output -raw bastion_instance_id)

# SSH (키 파일 경로 확인)
ssh -i cloud-infra-bastion.pem ec2-user@$BASTION_IP

# 접속되면
hostname    # cloud-infra-dev-bastion
exit
```

```bash
# SSM Session (플러그인 설치 필요)
aws ssm start-session --target $BASTION_ID --region ap-northeast-2
```

```bash
# 플러그인 없이 SSM Agent 동작만 확인
aws ssm describe-instance-information --region ap-northeast-2 \
  --filters "Key=InstanceIds,Values=$BASTION_ID" \
  --query 'InstanceInformationList[0].PingStatus'
# Online 이면 OK
```

---

## 5. “지금 무엇이 정상인가” 맵

```text
[로컬 PC]
  docker compose  →  FE:8080 / BE:3000     ← 앱 확인
  ssh / ssm       →  Bastion               ← 점프 서버 확인
  terraform/aws   →  VPC·NAT·SG            ← 네트워크 확인

[아직 없으면 정상]
  http://ALB...   →  EKS 앱 FE             ← Stage 4 후
```

---

## 6. destroy 전에 확인할 것

실습 끝내기 전:

```bash
./scripts/verify-lab.sh
# 콘솔에서 NAT available 2, Bastion running 확인
```

종료:

```bash
cd terraform
terraform destroy -auto-approve
./scripts/verify-lab.sh   # state empty / 리소스 없음 확인
```

destroy 후 콘솔:

- [ ] NAT gateways: available 없음  
- [ ] Bastion 인스턴스: terminated  
- [ ] VPC 삭제됨 (또는 프로젝트 태그 리소스 없음)

---

## 관련 문서

- [BASTION.md](BASTION.md) — Bastion 상세  
- [STAGE_1_APPLY.md](STAGE_1_APPLY.md) — 네트워크  
- [EKS_E2E_CHECKLIST.md](EKS_E2E_CHECKLIST.md) — AWS 위 FE 포함 전체 데모  
- [README 데모 시나리오](../README.md#데모-시나리오) — A 로컬 / B EKS  
