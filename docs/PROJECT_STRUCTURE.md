# 📁 프로젝트 파일 구조 및 역할 정의

| 항목 | 내용 |
|------|------|
| 문서 버전 | v1.1 |
| 정렬 기준 | [PRD.md](PRD.md) §5.3, [architecture.md](architecture.md) |
| 관련 문서 | [기능 명세서](FUNCTIONAL_SPEC.md), [STAGE_1_DEV_GUIDE.md](STAGE_1_DEV_GUIDE.md) |

### 설계 기준 (문서 통일)

| 항목 | 기준 |
|------|------|
| 서브넷 | **6개** (Public 2 + Web 2 + DB 2) — “8개” 표기는 사용하지 않음 |
| NAT / EIP | **각 2개** (AZ당 1) |
| Route Table | **5개** (Public 1 + Private Web AZ별 2 + Private DB AZ별 2) |
| Security Group | **4개** (alb / web_ec2 / bastion / rds), DB 포트 3306 필수 |

---

## 전체 프로젝트 구조

```
cicd/
│
├── .github/
│   └── workflows/              # GitHub Actions 파이프라인 (3단계에서 구현)
│
├── .gitignore                  # Git 제외 파일
│   ├── *.tfstate              # 로컬 Terraform 상태 파일
│   ├── terraform.tfvars        # 민감한 변수값
│   └── .terraform/             # 플러그인 디렉토리
│
├── README.md                   # 프로젝트 개요 및 빠른 시작
│
├── docs/
│   ├── PRD.md                  # 제품 요구사항
│   ├── FUNCTIONAL_SPEC.md      # 기능 명세서
│   ├── architecture.md         # 네트워크 아키텍처 (설계 SoT)
│   ├── PROJECT_STRUCTURE.md    # 📄 이 문서
│   ├── STAGE_1_DEV_GUIDE.md    # 1단계 개발 가이드
│   ├── STAGE_2_DEV_GUIDE.md    # 2단계 개발 가이드 (예정)
│   └── STAGE_3_DEV_GUIDE.md    # 3단계 개발 가이드 (예정)
│
└── terraform/                  # 📍 핵심 IaC 코드
    │
    ├── main.tf                 # ✅ Terraform Provider & Backend 설정
    │   └── 내용: aws provider, terraform 버전 요구사항, remote state 설정
    │
    ├── variables.tf            # ✅ 모든 입력 변수 정의
    │   └── 내용: aws_region, environment, project_name, VPC CIDR,
    │             서브넷 CIDR, my_ip 등 매개변수
    │
    ├── locals.tf               # ✅ 계산된 로컬 변수
    │   └── 내용: name_prefix, common_tags, availability_zones 등
    │
    ├── terraform.tfvars.example # ✅ 변수값 예제 (반드시 복사하여 사용)
    │   └── 사용법: cp terraform.tfvars.example terraform.tfvars
    │
    ├── terraform.tfvars         # ⚠️  .gitignore에 포함 (절대 커밋 금지!)
    │   └── 내용: 프로젝트 설정값 등 민감한 정보 (키 하드코딩 금지)
    │
    ├── vpc.tf                  # 📝 VPC & Internet Gateway
    │   ├── aws_vpc.main        # VPC 생성 (10.0.0.0/16)
    │   ├── aws_internet_gateway.main # IGW 생성
    │   └── data "aws_availability_zones" # AZ 데이터 소스
    │
    ├── subnets.tf              # 📝 Public/Private 서브넷 6개
    │   ├── aws_subnet.public      # Public 2 (AZ-A, AZ-C)
    │   ├── aws_subnet.private_web # Private Web 2
    │   └── aws_subnet.private_db  # Private DB 2
    │
    ├── nat.tf                  # 📝 NAT Gateway & Elastic IP (AZ별)
    │   ├── aws_eip.nat            # Elastic IP 2개
    │   └── aws_nat_gateway.main   # NAT Gateway 2개 (Public 서브넷 내)
    │
    ├── routing.tf              # 📝 라우팅 테이블 5개 & association 6개
    │   ├── aws_route_table.public       # Public RT → IGW
    │   ├── aws_route_table.private_web  # Private Web RT ×2 (AZ별 → 동일 AZ NAT)
    │   ├── aws_route_table.private_db   # Private DB RT ×2 (인터넷 경로 없음)
    │   └── aws_route_table_association  # 서브넷-RT 연결
    │
    ├── security_groups.tf      # 📝 보안 그룹 4개
    │   ├── aws_security_group.alb     # ALB SG (80, 443)
    │   ├── aws_security_group.web_ec2 # Web EC2 SG (ALB에서만)
    │   ├── aws_security_group.bastion # Bastion SG (my_ip만 SSH)
    │   └── aws_security_group.rds     # RDS SG (Web EC2 → 3306)
    │
    └── outputs.tf              # ✅ 생성된 리소스 ID/정보 출력
        ├── output "vpc_id"
        ├── output "public_subnet_ids"
        ├── output "private_web_subnet_ids"
        ├── output "private_db_subnet_ids"
        ├── output "security_group_ids"
        └── output "nat_gateway_ips"
```

---

## 🔑 주요 파일별 역할 상세 설명

### 1️⃣ **main.tf** - Terraform 설정 및 AWS Provider
```
목적: Terraform 프로바이더 및 전역 설정
상태: ✅ 완성
내용:
- AWS Provider 구성 (리전: ap-northeast-2)
- Terraform 최소 버전 요구사항 (v1.5+)
- 향후 S3 Remote State Backend 설정 (주석 처리됨)
- 공통 태그 자동 추가 (모든 리소스에 Environment, Project, CreatedAt 등)
```

**주의사항:**
- AWS 자격증명은 환경변수 또는 AWS CLI로 관리 (코드에 하드코딩 금지)
- Backend를 S3로 변경할 때만 수정

---

### 2️⃣ **variables.tf** - 입력 변수 정의
```
목적: Terraform 코드에서 사용할 모든 변수 선언
상태: ✅ 기본 정의 완료 (필요시 추가)
주요 변수:
  - aws_region: AWS 리전 (기본값: ap-northeast-2)
  - environment: 배포 환경 (dev/staging/prod)
  - project_name: 프로젝트명 (리소스 이름 접두사)
  - vpc_cidr: VPC CIDR 블록 (기본값: 10.0.0.0/16)
  - public_subnet_cidrs: Public 서브넷 CIDR 목록
  - private_web_subnet_cidrs: Private Web 서브넷 CIDR 목록
  - private_db_subnet_cidrs: Private DB 서브넷 CIDR 목록
  - my_ip: Bastion Host SSH 접속 허용 IP (개발자 공인 IP)
  - tags: 추가 태그 (선택사항)

검증 규칙:
- aws_region: 유효한 AWS 리전 형식 체크
- environment: dev/staging/prod 중 선택만 가능
- project_name: 15자 이하
- my_ip: CIDR 형식 검증
```

**⚠️ 중요:** `my_ip` 변수에는 반드시 "YOUR_PUBLIC_IP/32" 형태로 개발자 공인 IP 입력

---

### 3️⃣ **locals.tf** - 계산된 로컬 변수
```
목적: 여러 파일에서 재사용할 계산된 값 정의
상태: ✅ 완성
주요 로컬 변수:
  - name_prefix: 리소스 이름 규칙 (예: "cloud-infra-dev")
  - common_tags: 모든 리소스에 자동 추가될 태그
  - availability_zones: AZ 목록 (ap-northeast-2a, ap-northeast-2c)
  - az_count: AZ 개수 (2개)

예제 활용:
  Name = "${local.name_prefix}-vpc"  # cloud-infra-dev-vpc
  tags = local.common_tags           # 공통 태그 자동 포함
```

---

### 4️⃣ **terraform.tfvars.example** - 변수값 예제
```
목적: terraform.tfvars 작성 시 참고할 예제
상태: ✅ 완성
사용법:
  1. cp terraform.tfvars.example terraform.tfvars
  2. terraform.tfvars 파일 열기
  3. 본인 환경에 맞게 값 수정
  4. terraform apply 실행

⚠️ 주의: terraform.tfvars는 .gitignore에 포함되어 Git에 커밋되지 않음
         (AWS Access Key 등 민감한 정보 포함)
```

---

### 5️⃣ **vpc.tf** - VPC 및 Internet Gateway
```
목적: VPC 생성 및 인터넷 연결 구성
상태: ✅ 완성
포함 리소스:
  ✅ aws_vpc.main
     - CIDR: 10.0.0.0/16
     - DNS 활성화 (enable_dns_hostnames, enable_dns_support)
  
  ✅ aws_internet_gateway.main
     - VPC에 연결되어 Public 서브넷이 인터넷에 접근 가능하게 함
  
  ✅ data "aws_availability_zones"
     - 현재 리전의 사용 가능한 AZ 자동 탐지
```

---

### 6️⃣ **subnets.tf** - Public/Private 서브넷
```
목적: 3-Tier 아키텍처를 위한 서브넷 6개 생성
상태: 📝 작성 필요 (또는 코드 존재 시 PRD 기준 대조)
필수 구성 요소:

🔴 PUBLIC 서브넷 (2개)
   - 이름: cloud-infra-dev-public-subnet-ap-northeast-2a
   - 이름: cloud-infra-dev-public-subnet-ap-northeast-2c
   - 특징: map_public_ip_on_launch=true
   - 용도: ALB, Bastion, NAT Gateway 배치

🟡 PRIVATE WEB 서브넷 (2개)
   - 이름: cloud-infra-dev-private-web-subnet-ap-northeast-2a
   - 이름: cloud-infra-dev-private-web-subnet-ap-northeast-2c
   - 특징: 동일 AZ NAT로 아웃바운드만 가능
   - 용도: EC2 웹 서버 배치

🔵 PRIVATE DB 서브넷 (2개)
   - 이름: cloud-infra-dev-private-db-subnet-ap-northeast-2a
   - 이름: cloud-infra-dev-private-db-subnet-ap-northeast-2c
   - 특징: 인터넷 연결 없음 (VPC 내부 통신만)
   - 용도: RDS 배치 공간 (인스턴스는 S2 선택)

구현 형식: count로 AZ별 서브넷 생성
합계: 2 + 2 + 2 = 6개 (8개가 아님)
```

---

### 7️⃣ **nat.tf** - NAT Gateway 및 Elastic IP
```
목적: Private Web 서브넷의 아웃바운드 인터넷 연결 (HA)
상태: 📝 작성 필요 (또는 코드 존재 시 PRD 기준 대조)
필수 구성 요소 (권장 = AZ당 1개):

✅ aws_eip.nat (2개)
   - 이름: cloud-infra-dev-eip-natgw-ap-northeast-2a / -2c
   - 특징: NAT Gateway에 할당될 공인 IP
   - 비용: EIP·NAT 모두 상시 과금 가능 — 요금표는 AWS 최신 기준 확인

✅ aws_nat_gateway.main (2개)
   - 이름: cloud-infra-dev-natgw-ap-northeast-2a / -2c
   - 위치: 각 AZ Public 서브넷 내
   - 역할: 동일 AZ Private Web → 인터넷
   - depends_on: Internet Gateway

💰 비용 고려: 테스트 완료 후 terraform destroy 권장
   대안: 비용 절감 모드로 NAT 1개 (architecture.md 참고, 기본 아님)
```

---

### 8️⃣ **routing.tf** - 라우팅 테이블 및 경로
```
목적: 네트워크 트래픽 경로 정의
상태: 📝 작성 필요
필수 구성 요소:

🔴 PUBLIC ROUTE TABLE
   - 이름: cloud-infra-dev-rt-public
   - 라우트: 0.0.0.0/0 → Internet Gateway
   - 연결: Public 서브넷 2개

🟡 PRIVATE WEB ROUTE TABLE (AZ별 분리)
   - 이름: cloud-infra-dev-rt-private-web-ap-northeast-2a
   - 이름: cloud-infra-dev-rt-private-web-ap-northeast-2c
   - 라우트: 0.0.0.0/0 → NAT Gateway (같은 AZ)
   - 연결: Private Web 서브넷 (각 AZ별)
   - 💡 중요: 각 AZ의 Private Web 서브넷은 해당 AZ의 NAT로 라우팅

🔵 PRIVATE DB ROUTE TABLE (AZ별 분리)
   - 이름: cloud-infra-dev-rt-private-db-ap-northeast-2a
   - 이름: cloud-infra-dev-rt-private-db-ap-northeast-2c
   - 라우트: (인터넷 연결 없음)
   - 연결: Private DB 서브넷 (각 AZ별)
   - 특징: VPC 내부 통신만 가능

구현 형식: aws_route_table + aws_route + aws_route_table_association
```

---

### 9️⃣ **security_groups.tf** - 보안 그룹
```
목적: 3-Tier 아키텍처 보안 규칙 (최소 권한 원칙)
상태: 📝 작성 필요
필수 보안 그룹:

1️⃣ ALB 보안 그룹 (이름: cloud-infra-dev-sg-alb)
   Ingress (인바운드):
   - TCP 80 (HTTP): 0.0.0.0/0 (모든 IP)
   - TCP 443 (HTTPS): 0.0.0.0/0 (모든 IP)
   Egress (아웃바운드):
   - All (모든 프로토콜, 모든 포트): 0.0.0.0/0

2️⃣ Web EC2 보안 그룹 (이름: cloud-infra-dev-sg-web-ec2)
   Ingress (인바운드):
   - TCP 80 (HTTP): sg-alb (ALB 보안 그룹 ID)
   - TCP 443 (HTTPS): sg-alb (ALB 보안 그룹 ID)
   Egress (아웃바운드):
   - All: 0.0.0.0/0
   💡 목적: ALB에서만 트래픽 수신, 외부 직접 접속 차단

3️⃣ Bastion Host 보안 그룹 (이름: cloud-infra-dev-sg-bastion)
   Ingress (인바운드):
   - TCP 22 (SSH): var.my_ip (개발자 공인 IP, 예: 203.0.113.42/32)
   Egress (아웃바운드):
   - All: 0.0.0.0/0
   💡 목적: 개발자만 SSH 접속, 다른 모든 IP 차단

4️⃣ RDS 보안 그룹 (이름: cloud-infra-dev-sg-rds)
   Ingress (인바운드):
   - TCP 3306 (MySQL): sg-web-ec2  ← 필수
   - TCP 5432 (PostgreSQL): sg-web-ec2  ← 선택 (스택에 맞게)
   Egress (아웃바운드):
   - All: 0.0.0.0/0
   💡 목적: Web EC2에서만 DB 접속, 외부 접속 차단

구현 형식: aws_security_group (인라인 rule 또는 분리 rule 리소스)
```

---

### 🔟 **outputs.tf** - 출력값
```
목적: 생성된 리소스 ID/정보 출력 (다음 단계에서 참조용)
상태: ✅ 기본 정의 완료 (필요시 추가)
주요 출력값:
  - vpc_id: VPC ID (예: vpc-0123456789abcdef)
  - public_subnet_ids: Public 서브넷 ID 목록
  - private_web_subnet_ids: Private Web 서브넷 ID 목록
  - private_db_subnet_ids: Private DB 서브넷 ID 목록
  - security_group_ids: 보안 그룹 ID 맵
  - nat_gateway_ips: NAT Gateway 공인 IP 목록

콘솔 출력 명령:
  terraform output              # 모든 출력값 표시
  terraform output vpc_id       # 특정 출력값만 표시
  terraform output -json        # JSON 형식 출력
```

---

## 🎯 1단계 완성 상태 매트릭스

> 상태 열은 **문서 기준 목표**이다. 실제 `terraform/*.tf` 내용은 코드 대조 후 갱신한다.

| 파일 | 문서상 목표 | 다음 액션 |
|------|-------------|----------|
| main.tf | ✅ Provider/버전 | 그대로 사용, remote state는 이후 |
| variables.tf | ✅ 기본 변수 | my_ip 등 검증 유지 |
| locals.tf | ✅ name_prefix/tags/AZ | 그대로 사용 |
| terraform.tfvars.example | ✅ 예제 | 복사 후 my_ip 설정 |
| **vpc.tf** | VPC + IGW | architecture 기준 확인 |
| **subnets.tf** | **서브넷 6개** | Public/Web/DB × 2 AZ |
| **nat.tf** | **EIP 2 + NAT 2** | AZ별 Public 배치 |
| **routing.tf** | **RT 5 + association 6** | Web→동일 AZ NAT, DB 무인터넷 |
| **security_groups.tf** | **SG 4개** | 3306 필수, 5432 선택 |
| outputs.tf | vpc/subnet/sg/nat | plan/output 검증 |

### Stage 1 plan 기대치 (요약)

- Subnet 6 / NAT 2 / EIP 2 / RT 5 / SG 4  
- 상세: [architecture.md](architecture.md) 검증 섹션, [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) F-NET·F-SEC

---

## 🚀 1단계 실행 명령어 요약

```bash
# 1. terraform 디렉토리 이동
cd terraform/

# 2. 변수값 파일 생성
cp terraform.tfvars.example terraform.tfvars
# my_ip 등 본인 환경에 맞게 수정

# 3. Terraform 초기화
terraform init

# 4. 문법 검사 및 포맷팅
terraform fmt -recursive
terraform validate

# 5. 변경 계획 확인
terraform plan -out=tfplan

# 6. 배포 (생성)
terraform apply tfplan

# 7. 생성된 리소스 확인
terraform output

# 8. 테스트 완료 후 정리 (NAT 과금 주의)
terraform destroy
```

---

**관련 문서**

- 요구사항: [PRD.md](PRD.md)
- 수락 기준: [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md)
- 네트워크 설계: [architecture.md](architecture.md)
- 구현 절차: [STAGE_1_DEV_GUIDE.md](STAGE_1_DEV_GUIDE.md)

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | (초기) | 초안 |
| v1.1 | 2026-07-16 | PRD 정렬 — 서브넷 6, RT 5, docs 목록, SG/RDS 포트 |
