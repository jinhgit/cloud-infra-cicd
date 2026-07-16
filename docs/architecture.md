# 1단계 아키텍처 문서: Terraform 인프라 코드화

| 항목 | 내용 |
|------|------|
| 문서 버전 | v1.1 |
| 정렬 기준 | [PRD.md](PRD.md) §5.3 설계 권장안 |
| 관련 문서 | [기능 명세서](FUNCTIONAL_SPEC.md), [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md), [STAGE_1_DEV_GUIDE.md](STAGE_1_DEV_GUIDE.md) |

본 문서는 **Stage 1 네트워크 설계의 단일 기준(Source of Truth)** 이다.  
구현·검증 시 아래 권장 구성을 따른다.

### 설계 기준 요약 (PRD 정렬)

| 항목 | 기준 값 |
|------|---------|
| 서브넷 | **6개** (Public 2 + Private Web 2 + Private DB 2) |
| NAT Gateway | **AZ당 1개 = 총 2개** (+ EIP 2개) |
| Route Table | **5개** (Public 1 + Private Web AZ별 2 + Private DB AZ별 2) |
| 보안 그룹 | **4개** (ALB / Web EC2 / Bastion / RDS) |
| DB SG 포트 | **3306 필수**, 5432는 선택 |
| AZ | `ap-northeast-2a`, `ap-northeast-2c` |

> **비용 절감 모드(대안):** NAT 1개만 두고 모든 Private Web이 해당 NAT로 라우팅.  
> 기본(권장) 구성이 아니며, 사용 시 README에 “비용 절감 모드”로 명시한다.

---

## 📐 네트워크 아키텍처 개요

```
┌────────────────────────────────────────────────────────────────────────────┐
│                  AWS Region: ap-northeast-2                                │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                   VPC (10.0.0.0/16)                                 │  │
│  │                                                                      │  │
│  │  ┌────────────────────────┐  ┌──────────────────────────────────┐  │  │
│  │  │  ap-northeast-2a (AZ-A)│  │  ap-northeast-2c (AZ-C)          │  │  │
│  │  ├────────────────────────┼──┼──────────────────────────────────┤  │  │
│  │  │ Public Subnet          │  │ Public Subnet                    │  │  │
│  │  │ (10.0.1.0/24)          │  │ (10.0.2.0/24)                    │  │  │
│  │  │ ├─ Bastion Host (SSH)  │  │ ├─ ALB (다중 AZ)                 │  │  │
│  │  │ ├─ NAT GW + EIP (AZ-A) │  │ ├─ NAT GW + EIP (AZ-C)           │  │  │
│  │  │ └─ RT: 0.0.0.0/0 → IGW │  │ └─ RT: 0.0.0.0/0 → IGW           │  │  │
│  │  ├────────────────────────┼──┼──────────────────────────────────┤  │  │
│  │  │ Private Web            │  │ Private Web                      │  │  │
│  │  │ (10.0.10.0/24)         │  │ (10.0.11.0/24)                   │  │  │
│  │  │ ├─ EC2 Web (Private IP)│  │ ├─ EC2 Web (Private IP)          │  │  │
│  │  │ └─ RT: 0.0.0.0/0 →     │  │ └─ RT: 0.0.0.0/0 →               │  │  │
│  │  │      NAT (AZ-A)        │  │      NAT (AZ-C)                  │  │  │
│  │  ├────────────────────────┼──┼──────────────────────────────────┤  │  │
│  │  │ Private DB             │  │ Private DB                       │  │  │
│  │  │ (10.0.20.0/24)         │  │ (10.0.21.0/24)                   │  │  │
│  │  │ ├─ RDS 배치 공간       │  │ ├─ RDS 배치 공간                 │  │  │
│  │  │ └─ RT: 인터넷 경로 없음│  │ └─ RT: 인터넷 경로 없음          │  │  │
│  │  └────────────────────────┘  └──────────────────────────────────┘  │  │
│  │                                                                      │  │
│  │  Internet Gateway (IGW) — Public 서브넷 ↔ 인터넷                    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

**핵심 원칙**

- Private Web의 아웃바운드는 **동일 AZ의 NAT** 로 보낸다 (교차 AZ 데이터 요금·단일 장애점 완화).
- Private DB에는 **`0.0.0.0/0` 인터넷 라우트를 두지 않는다**.
- ALB·NAT·Bastion은 Public, 웹/DB 워크로드는 Private.

---

## 🔐 보안 그룹 (Security Group) 규칙

Terraform 리소스명은 `aws_security_group.alb` / `web_ec2` / `bastion` / `rds` 를 기준으로 한다.  
태그 Name 예: `cloud-infra-dev-sg-alb`.

### 1. ALB 보안 그룹 (`sg-alb`)

| 방향 | 프로토콜 | 포트 | 소스/대상 | 설명 |
|------|---------|------|---------|------|
| Ingress | TCP | 80 | 0.0.0.0/0 | HTTP |
| Ingress | TCP | 443 | 0.0.0.0/0 | HTTPS (리스너 구현 시) |
| Egress | All | All | 0.0.0.0/0 | 백엔드 전달 등 |

### 2. Web EC2 보안 그룹 (`sg-web-ec2`)

| 방향 | 프로토콜 | 포트 | 소스/대상 | 설명 |
|------|---------|------|---------|------|
| Ingress | TCP | 80 | sg-alb | ALB HTTP만 |
| Ingress | TCP | 443 | sg-alb | ALB HTTPS만 (필요 시) |
| Egress | All | All | 0.0.0.0/0 | 패키지 업데이트·외부 API 등 |

> **S2 권장(선택):** Bastion SG → Web EC2 TCP 22 허용 시, 운영 점프 경로로 README에 명시.

### 3. Bastion 보안 그룹 (`sg-bastion`)

| 방향 | 프로토콜 | 포트 | 소스/대상 | 설명 |
|------|---------|------|---------|------|
| Ingress | TCP | 22 | `var.my_ip` (/32) | 개발자 IP만 SSH |
| Egress | All | All | 0.0.0.0/0 | 관리 트래픽 |

### 4. RDS 보안 그룹 (`sg-rds`)

| 방향 | 프로토콜 | 포트 | 소스/대상 | 설명 |
|------|---------|------|---------|------|
| Ingress | TCP | **3306** | sg-web-ec2 | MySQL **필수** |
| Ingress | TCP | 5432 | sg-web-ec2 | PostgreSQL **선택** |
| Egress | All | All | 0.0.0.0/0 | (필요 시 축소 가능) |

Stage 1에서는 **SG + Private DB 서브넷 공간 확보**가 목표이다. RDS 인스턴스 자체는 Stage 2 선택(P2).

---

## 📊 라우팅 테이블 (Routing Table) 설정

### Public 라우팅 테이블 (1개)

```
대상           다음홉
----           ------
10.0.0.0/16   Local
0.0.0.0/0     Internet Gateway
```

**연결:** Public 서브넷 2개 (`10.0.1.0/24`, `10.0.2.0/24`)

### Private Web 라우팅 테이블 (AZ별 2개)

**AZ-A**

```
대상           다음홉
----           ------
10.0.0.0/16   Local
0.0.0.0/0     NAT Gateway (AZ-A)
```

**연결:** Private Web `10.0.10.0/24`

**AZ-C**

```
대상           다음홉
----           ------
10.0.0.0/16   Local
0.0.0.0/0     NAT Gateway (AZ-C)
```

**연결:** Private Web `10.0.11.0/24`

### Private DB 라우팅 테이블 (AZ별 2개)

```
대상           다음홉
----           ------
10.0.0.0/16   Local
(인터넷 기본 경로 없음)
```

**연결:**

- AZ-A: `10.0.20.0/24`
- AZ-C: `10.0.21.0/24`

**합계:** Route Table **5개** + 각 서브넷 association **6개**.

---

## 🛠️ Terraform 리소스 매핑

### VPC 및 네트워크 계층

| 리소스 | 설정값 | 파일 | 설명 |
|--------|--------|------|------|
| `aws_vpc` | 10.0.0.0/16 | `vpc.tf` | VPC |
| `aws_internet_gateway` | - | `vpc.tf` | IGW |
| `aws_subnet` (Public) | 10.0.1.0/24, 10.0.2.0/24 | `subnets.tf` | Public 2 |
| `aws_subnet` (Private Web) | 10.0.10.0/24, 10.0.11.0/24 | `subnets.tf` | Web 2 |
| `aws_subnet` (Private DB) | 10.0.20.0/24, 10.0.21.0/24 | `subnets.tf` | DB 2 |

### NAT 및 라우팅

| 리소스 | 개수/설정 | 파일 | 설명 |
|--------|-----------|------|------|
| `aws_eip` | **2** (AZ별) | `nat.tf` | NAT용 EIP |
| `aws_nat_gateway` | **2** (각 Public 서브넷) | `nat.tf` | HA 아웃바운드 |
| `aws_route_table` | **5** | `routing.tf` | Public 1 + Web 2 + DB 2 |
| `aws_route` / association | IGW·NAT·subnet 연결 | `routing.tf` | 경로·연결 |

### 보안 그룹

| 리소스 | 용도 | 파일 | 규칙 (기준) |
|--------|------|------|-------------|
| `aws_security_group.alb` | ALB | `security_groups.tf` | 80/443 in + egress |
| `aws_security_group.web_ec2` | Web | `security_groups.tf` | ALB→80/443 only |
| `aws_security_group.bastion` | Bastion | `security_groups.tf` | my_ip→22 |
| `aws_security_group.rds` | RDS | `security_groups.tf` | Web→3306 (+5432 선택) |

---

## 🔄 트래픽 흐름 (Communication Flow)

### 1️⃣ 인터넷 → ALB → Web EC2

```
인터넷 사용자
    → 80/443
    → Internet Gateway
    → Public 서브넷 (ALB)
    → (sg-alb 허용)
    → Private Web 서브넷 EC2
    → (sg-web-ec2: ALB 소스만 허용)
```

### 2️⃣ Web EC2 → DB

```
Web EC2 (Private Web)
    → 3306 (필수) / 5432 (선택)
    → Private DB 서브넷
    → (sg-rds: Web EC2 SG만 허용)
```

### 3️⃣ Private Web → 인터넷 (아웃바운드)

```
Web EC2
    → RT: 0.0.0.0/0 → 동일 AZ NAT Gateway
    → EIP
    → IGW
    → 인터넷
```

> Private DB 계층은 기본적으로 위 경로를 **사용하지 않는다** (인터넷 라우트 없음).

### 4️⃣ 개발자 → Bastion (SSH)

```
개발자 공인 IP (my_ip/32)
    → SSH 22
    → (sg-bastion)
    → Public 서브넷 Bastion
    → (선택, S2) Private Web EC2 SSH
```

---

## ✅ 검증 항목

### Terraform Plan 검증 (Stage 1 예상)

```bash
cd terraform
terraform plan
```

예상 산출물 (권장 구성):

| 항목 | 개수 |
|------|------|
| VPC | 1 |
| Internet Gateway | 1 |
| Subnet | **6** (Public 2 + Web 2 + DB 2) |
| Elastic IP (NAT) | **2** |
| NAT Gateway | **2** |
| Route Table | **5** |
| Route Table Association | **6** |
| Security Group | **4** |

**총 리소스 수: 약 25~35개** (association·route·태그 리소스 포함 시 변동)

### AWS Console 검증 (배포 후)

- [ ] VPC CIDR `10.0.0.0/16`
- [ ] 서브넷 6개가 올바른 AZ·CIDR에 배치
- [ ] NAT 2개가 각각 Public AZ-A / AZ-C에 위치
- [ ] Private Web AZ-A → NAT-A, AZ-C → NAT-C
- [ ] Private DB에 인터넷 기본 경로 없음
- [ ] SG 규칙이 표와 일치 (`my_ip` 포함)

---

## 📝 CIDR 계획 (IP 주소 할당)

```
VPC: 10.0.0.0/16 (총 65,536개 IP)
│
├── Public Tier (2개, 각 /24)
│   ├── 10.0.1.0/24   (AZ-A)
│   └── 10.0.2.0/24   (AZ-C)
│
├── Private Web Tier (2개, 각 /24)
│   ├── 10.0.10.0/24  (AZ-A)
│   └── 10.0.11.0/24  (AZ-C)
│
└── Private DB Tier (2개, 각 /24)
    ├── 10.0.20.0/24  (AZ-A)
    └── 10.0.21.0/24  (AZ-C)

AWS 예약 (각 서브넷):
  .0 network / .1 VPC router / .2 DNS / .3 예약 / .255 broadcast (전통적 표기)
```

---

## 🚀 배포 명령어

```bash
cd terraform
terraform init

cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars에서 my_ip 수정 (예: "x.x.x.x/32")

terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output

# 테스트 완료 후 — NAT 과금 주의
terraform destroy
```

---

## 💡 주요 고려사항

1. **고가용성**
   - 2 AZ에 서브넷·NAT·(S2) ALB 타깃 분산
   - AZ 장애 시 해당 AZ NAT/워크로드만 영향, 다른 AZ 경로 유지

2. **비용**
   - NAT 2개 + EIP는 **상시 과금** → 작업 후 `destroy` 권장
   - 학습 중 단기 비용 절감이 필요하면 비용 절감 모드(NAT 1) 검토

3. **보안**
   - 최소 권한 SG, Bastion `my_ip` 제한
   - 시크릿·`terraform.tfvars`·state 미커밋 ([PRD NFR](PRD.md))

4. **확장성**
   - Private Web에 EC2 추가 용이
   - DB 서브넷은 Multi-AZ RDS 배치에 대비

---

## 🔗 다음 단계 (2단계)

- Bastion Host EC2
- Web Server EC2 2대 (ALB Target)
- Application Load Balancer + Target Group + Health Check
- User Data로 Nginx 자동 기동
- RDS 인스턴스 (선택, P2)

상세 수락 기준: [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) F-CMP-*  
요구사항 원문: [PRD.md](PRD.md)

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | (초기) | 초안 |
| v1.1 | 2026-07-16 | PRD 권장안 정렬 — NAT 2, RT 5, 서브넷 6, SG 명명·포트 정리 |
