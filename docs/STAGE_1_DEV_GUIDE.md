# 📋 [1단계] Terraform 인프라 코드화 개발 가이드

| 항목 | 내용 |
|------|------|
| 목표 | Terraform으로 3-Tier 고가용성 네트워크를 AWS에 구축 |
| 기간 | 1~2주 |
| 정렬 기준 | [PRD.md](PRD.md), [architecture.md](architecture.md), [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) |
| 문서 버전 | v1.1 (2026-07-16) |

### 설계 기준 (반드시 준수)

| 항목 | 값 |
|------|-----|
| 서브넷 | **6개** (Public 2 + Private Web 2 + Private DB 2) |
| NAT / EIP | **각 2개** (AZ당 1, Public 서브넷 배치) |
| Route Table | **5개** (Public 1 + Web AZ별 2 + DB AZ별 2) |
| Security Group | **4개** (alb / web_ec2 / bastion / rds) |
| DB 포트 | **3306 필수**, 5432 선택 |
| AZ | `ap-northeast-2a`, `ap-northeast-2c` |

---

## 📁 1단계 파일 구조

```
terraform/
├── main.tf                      # Provider 설정 & 백엔드
├── variables.tf                 # 변수 정의
├── outputs.tf                   # 출력값 정의
├── locals.tf                    # 로컬 변수
├── terraform.tfvars.example     # 변수 값 예제
│
├── vpc.tf                       # VPC + Internet Gateway
├── subnets.tf                   # 서브넷 6개
├── routing.tf                   # 라우팅 테이블 5개 + association
├── nat.tf                       # NAT Gateway 2 + EIP 2
├── security_groups.tf           # 보안 그룹 4개
│
└── (루트 .gitignore)            # state / tfvars 제외

docs/
├── PRD.md
├── FUNCTIONAL_SPEC.md
├── architecture.md              # 네트워크 설계 SoT
├── PROJECT_STRUCTURE.md
└── STAGE_1_DEV_GUIDE.md         # 📄 이 문서
```

---

## 🎯 1단계 구현 범위 (요구사항)

### ✅ 구성 요소별 필수 리소스

| 구성 요소 | 리소스명 | 파일 | 상태 |
|----------|---------|------|------|
| **네트워크 기초** | VPC | `vpc.tf` | 🔄 진행중 |
| | Internet Gateway | `vpc.tf` | 🔄 진행중 |
| **Public 서브넷** | Public Subnet AZ-A | `subnets.tf` | 🔄 진행중 |
| | Public Subnet AZ-C | `subnets.tf` | 🔄 진행중 |
| **Private Web 서브넷** | Private Web Subnet AZ-A | `subnets.tf` | 🔄 진행중 |
| | Private Web Subnet AZ-C | `subnets.tf` | 🔄 진행중 |
| **Private DB 서브넷** | Private DB Subnet AZ-A | `subnets.tf` | 🔄 진행중 |
| | Private DB Subnet AZ-C | `subnets.tf` | 🔄 진행중 |
| **NAT & 아웃바운드** | Elastic IP (AZ-A) | `nat.tf` | 🔄 진행중 |
| | Elastic IP (AZ-C) | `nat.tf` | 🔄 진행중 |
| | NAT Gateway (AZ-A) | `nat.tf` | 🔄 진행중 |
| | NAT Gateway (AZ-C) | `nat.tf` | 🔄 진행중 |
| **라우팅** | Public Route Table | `routing.tf` | 🔄 진행중 |
| | Public Route (IGW) | `routing.tf` | 🔄 진행중 |
| | Public Subnet Route Table 연결 | `routing.tf` | 🔄 진행중 |
| | Private Web Route Table (각 AZ) | `routing.tf` | 🔄 진행중 |
| | Private Web Route (NAT) | `routing.tf` | 🔄 진행중 |
| | Private DB Route Table (각 AZ) | `routing.tf` | 🔄 진행중 |
| **보안** | ALB 보안 그룹 | `security_groups.tf` | 🔄 진행중 |
| | Web EC2 보안 그룹 | `security_groups.tf` | 🔄 진행중 |
| | Bastion Host 보안 그룹 | `security_groups.tf` | 🔄 진행중 |
| | RDS 보안 그룹 | `security_groups.tf` | 🔄 진행중 |

---

## 🚀 단계별 개발 절차

### **📍 STEP 1: 환경 준비 (1시간)**

#### 1-1. 필수 도구 설치 확인
```bash
# Terraform 설치 확인 (v1.5+)
terraform --version

# AWS CLI 설치 확인
aws --version

# AWS 자격증명 설정
aws configure
# 다음 정보 입력:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region name: ap-northeast-2
# - Default output format: json
```

#### 1-2. 작업 디렉토리 이동 및 초기화
```bash
# terraform 디렉토리로 이동
cd /Users/macbook/Desktop/SoloProject/cicd/terraform

# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars
```

#### 1-3. terraform.tfvars 설정
```bash
# terraform.tfvars 파일을 열어 다음 값 수정:
nano terraform.tfvars
```

**수정 항목:**
```hcl
# AWS 리전
aws_region = "ap-northeast-2"

# 프로젝트 메타데이터
environment  = "dev"
project_name = "cloud-infra"

# VPC CIDR
vpc_cidr = "10.0.0.0/16"

# 서브넷 CIDR (그대로 두기)
public_subnet_cidrs         = ["10.0.1.0/24", "10.0.2.0/24"]
private_web_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
private_db_subnet_cidrs     = ["10.0.20.0/24", "10.0.21.0/24"]

# 본인의 공인 IP 입력 (예: "203.0.113.42/32")
# https://www.whatismyipaddress.com 에서 확인 후 입력
my_ip = "YOUR_PUBLIC_IP/32"
```

---

### **📍 STEP 2: VPC 및 Internet Gateway 구현 (30분)**

**파일:** `vpc.tf`  
**목표:** VPC와 IGW 생성

#### 2-1. 현재 코드 확인
```bash
# vpc.tf 파일 검토 - 이미 구현됨
cat terraform/vpc.tf
```

#### 2-2. 검증
```bash
terraform validate
# ✅ Success: Valid configuration 확인
```

---

### **📍 STEP 3: 서브넷 구현 (1시간)**

**파일:** `subnets.tf`  
**목표:** Public/Private Web/DB 서브넷 **6개** 생성 (2+2+2)

#### 3-1. subnets.tf 작성해야 할 내용

**필수 포함 사항:**
- ✅ Public 서브넷 2개 (각 AZ)
- ✅ Private Web 서브넷 2개 (각 AZ)
- ✅ Private DB 서브넷 2개 (각 AZ)
- ✅ 합계 **6개** (8개가 아님)
- ✅ 각 서브넷에 가용영역(AZ) 명시
- ✅ 각 서브넷에 태그 추가

**구현 형식 예시:**
```hcl
# ===================================================
# Public 서브넷
# ===================================================

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true  # 💡 공인 IP 자동 할당 (Public 서브넷 필수)

  tags = {
    Name = "${local.name_prefix}-public-subnet-${local.availability_zones[count.index]}"
    Type = "Public"
  }
}

# 유사하게 private-web, private-db 서브넷 작성
```

#### 3-2. 검증
```bash
terraform fmt                 # 코드 포맷팅
terraform validate            # 문법 검사
terraform plan -out=tfplan    # 변경 계획 저장
```

---

### **📍 STEP 4: NAT Gateway 및 Elastic IP 구현 (45분)**

**파일:** `nat.tf`  
**목표:** Private 서브넷의 아웃바운드 인터넷 연결 구성

#### 4-1. nat.tf 작성해야 할 내용

**필수 포함 사항:**
- ✅ Elastic IP 2개 (각 AZ, Public 서브넷 내)
- ✅ NAT Gateway 2개 (각 AZ, Public 서브넷 내)

**구현 형식 예시:**
```hcl
# ===================================================
# Elastic IP for NAT Gateway
# ===================================================

resource "aws_eip" "nat" {
  count    = 2
  domain   = "vpc"
  tags = {
    Name = "${local.name_prefix}-eip-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===================================================
# NAT Gateway (Public 서브넷에 배치)
# ===================================================

resource "aws_nat_gateway" "main" {
  count           = 2
  allocation_id   = aws_eip.nat[count.index].id
  subnet_id       = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}
```

#### 4-2. 검증
```bash
terraform validate
terraform plan -out=tfplan
```

---

### **📍 STEP 5: 라우팅 테이블 구현 (1시간 30분)**

**파일:** `routing.tf`  
**목표:** 트래픽 라우팅 규칙 정의

#### 5-1. routing.tf 작성해야 할 내용

**필수 포함 사항 (합계 RT 5개 + association 6개):**
- ✅ Public Route Table 1개
- ✅ Public Route: 0.0.0.0/0 → IGW
- ✅ Public 서브넷 2개에 Route Table 연결
- ✅ Private Web Route Table 2개 (AZ별)
- ✅ Private Web Route: 0.0.0.0/0 → **동일 AZ** NAT Gateway
- ✅ Private Web 서브넷 각 AZ별 RT 연결
- ✅ Private DB Route Table 2개 (AZ별, 인터넷 경로 없음)
- ✅ Private DB 서브넷 각 AZ별 RT 연결

**구현 형식 예시:**
```hcl
# ===================================================
# Public Route Table
# ===================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

# Public 서브넷과 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 유사하게 Private Web, Private DB Route Table 작성
```

#### 5-2. 검증
```bash
terraform validate
terraform plan -out=tfplan | head -50  # 변경 내역 미리보기
```

---

### **📍 STEP 6: 보안 그룹 구현 (1시간)**

**파일:** `security_groups.tf`  
**목표:** 3-Tier 아키텍처 보안 규칙 정의

#### 6-1. security_groups.tf 작성해야 할 내용

**필수 보안 그룹 4개:**

| 보안 그룹 | Ingress 규칙 | Egress 규칙 |
|---------|------------|-----------|
| **ALB SG** | TCP 80 (0.0.0.0/0)<br>TCP 443 (0.0.0.0/0) | All (0.0.0.0/0) |
| **Web EC2 SG** | TCP 80 (ALB SG)<br>TCP 443 (ALB SG) | All (0.0.0.0/0) |
| **Bastion SG** | TCP 22 (MY_IP/32) | All (0.0.0.0/0) |
| **RDS SG** | TCP 3306 (Web EC2 SG) 필수<br>TCP 5432 (선택) | All (0.0.0.0/0) |

**구현 형식 예시:**
```hcl
# ===================================================
# ALB 보안 그룹
# ===================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-sg-alb"
  description = "ALB 보안 그룹"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-alb"
  }
}

# 유사하게 Web EC2, Bastion, RDS SG 작성
```

#### 6-2. 검증
```bash
terraform validate
terraform plan -out=tfplan
```

---

### **📍 STEP 7: 전체 계획 검토 및 변수 추가 (1시간)**

#### 7-1. variables.tf에 누락된 변수 추가

**확인 사항:**
- ✅ `my_ip` 변수 정의 확인
- ✅ `tags` 변수 (선택사항) 추가

**추가할 변수 (필요시):**
```hcl
variable "my_ip" {
  description = "Bastion Host SSH 접속 허용 IP (예: 203.0.113.42/32)"
  type        = string
  
  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", var.my_ip))
    error_message = "유효한 CIDR 형식이어야 합니다 (예: 203.0.113.42/32)"
  }
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
```

#### 7-2. outputs.tf 검토 및 추가

**필수 출력값:**
```hcl
# 보안 그룹 ID
output "security_group_ids" {
  description = "생성된 보안 그룹 ID"
  value = {
    alb_sg          = aws_security_group.alb.id
    web_ec2_sg      = aws_security_group.web_ec2.id
    bastion_sg      = aws_security_group.bastion.id
    rds_sg          = aws_security_group.rds.id
  }
}

# 서브넷 ID 정보
output "subnet_details" {
  description = "모든 서브넷 정보"
  value = {
    public_subnets         = aws_subnet.public[*].id
    private_web_subnets    = aws_subnet.private_web[*].id
    private_db_subnets     = aws_subnet.private_db[*].id
  }
}

# NAT Gateway 정보
output "nat_gateway_ips" {
  description = "NAT Gateway 공인 IP"
  value       = aws_eip.nat[*].public_ip
}
```

---

### **📍 STEP 8: Terraform 초기화 및 배포 (30분)**

#### 8-1. Terraform 초기화
```bash
# 플러그인 다운로드 및 초기 설정
terraform init
# ✅ Terraform has been successfully configured 확인
```

#### 8-2. 최종 검증
```bash
# 문법 검사
terraform validate
# ✅ Success: Valid configuration

# 코드 포맷팅
terraform fmt -recursive

# 변경 계획 확인
terraform plan -out=tfplan
```

#### 8-3. 테스트 배포 (DEV 환경)
```bash
# 배포 (변경 사항 적용)
terraform apply tfplan

# 💡 배포 소요 시간: 약 5~10분
# ✅ Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

#### 8-4. 배포 결과 확인
```bash
# 출력값 표시
terraform output

# AWS 콘솔 확인 (PRD/architecture 기준)
# 1. VPC 생성 확인
# 2. 서브넷 6개 생성 확인 (Public2 + Web2 + DB2)
# 3. NAT Gateway 2개 + EIP 2개 확인 (AZ별)
# 4. 라우팅 테이블 5개 확인 (Public1 + Web2 + DB2)
# 5. Private Web이 동일 AZ NAT를 가리키는지 확인
# 6. 보안 그룹 4개 생성 확인
```

#### 8-5. 리소스 정리 (테스트 후)
```bash
# 모든 리소스 삭제 (비용 절감)
terraform destroy

# 💡 리소스 삭제 확인: yes 입력
# ✅ Destroy complete!
```

---

## ✅ 1단계 완료 체크리스트

### 🔧 Terraform 코드 작성
- [ ] `vpc.tf`: VPC + IGW 작성 및 검증
- [ ] `subnets.tf`: **6개** 서브넷 작성 및 검증
- [ ] `nat.tf`: NAT Gateway **2** + EIP **2** 작성 및 검증
- [ ] `routing.tf`: RT **5** + association **6** 작성 및 검증
- [ ] `security_groups.tf`: 4개 보안 그룹 (RDS 3306 필수)
- [ ] `variables.tf`: 모든 필수 변수 정의 확인
- [ ] `outputs.tf`: 주요 출력값 정의 확인

### 📋 설정 및 테스트
- [ ] `terraform.tfvars` 파일 생성 (`.gitignore`에서 제외됨)
- [ ] `my_ip` 값 정확히 설정
- [ ] `terraform validate` 성공
- [ ] `terraform plan` 미리보기 확인
- [ ] `terraform apply` 성공적 배포
- [ ] AWS 콘솔에서 모든 리소스 생성 확인

### 🔐 보안 및 검증
- [ ] `terraform.tfvars` Git 커밋 안 함 (`.gitignore` 확인)
- [ ] AWS Access Key/Secret Key 환경변수 또는 AWS CLI로만 관리
- [ ] 보안 그룹 규칙 3-Tier 아키텍처에 맞게 설정
- [ ] ALB에서 Private Web으로의 라우팅 확인
- [ ] Private Web에서 NAT Gateway를 통한 아웃바운드 확인
- [ ] Private DB는 VPC 내부 통신만 가능 확인

### 📚 문서화
- [ ] 배포 절차 README.md에 기록
- [ ] 생성된 리소스 ID 정리
- [ ] 주요 IP 범위 기록
- [ ] 이슈 발생 시 해결 방법 문서화

---

## 📞 문제 해결 (Troubleshooting)

### 문제 1: `terraform init` 실패
**원인:** AWS 자격증명 미설정  
**해결:**
```bash
# AWS CLI 자격증명 설정
aws configure

# 또는 환경변수로 설정
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
export AWS_DEFAULT_REGION="ap-northeast-2"
```

### 문제 2: `terraform plan` 시 리소스 참조 오류
**원인:** 파일 간 리소스 참조 오류  
**확인:**
```bash
# 모든 tf 파일 나열
ls -la terraform/*.tf

# 리소스 정의 확인 (예: aws_vpc.main)
grep -n "resource \"aws_vpc" terraform/*.tf

# 리소스 참조 확인 (예: aws_vpc.main.id)
grep -n "aws_vpc.main.id" terraform/*.tf
```

### 문제 3: NAT Gateway 생성 후 비용 발생
**원인:** NAT Gateway 사용 요금 (시간당 $0.32 + 데이터 전송료)  
**해결:**
```bash
# 테스트 완료 후 즉시 삭제
terraform destroy
```

### 문제 4: 보안 그룹 규칙 적용이 안 됨
**확인:**
```bash
# 보안 그룹 상세 정보 확인
aws ec2 describe-security-groups --region ap-northeast-2 --filters "Name=vpc-id,Values=vpc-xxx"

# 규칙 재검토 (소스 CIDR 또는 SG ID 확인)
terraform plan -out=tfplan | grep -A5 "security_group"
```

---

## 📖 추가 리소스 및 학습 자료

### 프로젝트 내부
- [PRD.md](PRD.md) — 요구사항·범위
- [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) — F-NET / F-SEC 수락 기준, Stage 1 DoD
- [architecture.md](architecture.md) — 네트워크 설계 SoT
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) — 파일 역할

### 외부
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS VPC 가이드:** https://docs.aws.amazon.com/vpc/latest/userguide/
- **Terraform Best Practices:** https://www.terraform.io/cloud-docs/recommended-practices

---

**다음 단계:** 2단계 서버 설정 자동화 (Nginx, EC2, ALB) — 기능 명세 F-CMP-*

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | (초기) | 초안 |
| v1.1 | 2026-07-16 | PRD 정렬 — 서브넷 6, RT 5, NAT 2, docs 링크 |
