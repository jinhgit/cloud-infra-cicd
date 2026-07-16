# IaC 기반 클라우드 네트워크 자동화 및 CI/CD 파이프라인

클라우드 엔지니어로서 **Terraform을 이용한 인프라 코드화**, **3-Tier 보안 네트워크**, **Amazon EKS 워크로드(ALB Ingress)**, **GitHub Actions CI/CD**를 실현하는 프로젝트입니다.

## 📋 프로젝트 개요

- **목표**: Terraform으로 AWS 인프라를 코드화하고, GitHub Actions를 통한 자동 배포 파이프라인 구축
- **기간**: 계절학기 (3~4주)
- **핵심 가치**: 
  - 수동 콘솔 작업 → 100% 코드화
  - 인적 오류 최소화 및 배포 속도 향상
  - 테스트 비용 절감 (`terraform destroy` 한 번에 정리)

## 📚 프로젝트 문서

요구사항·설계·구현 가이드는 `docs/`에 정리되어 있습니다.

| 문서 | 설명 |
|------|------|
| [PRD](docs/PRD.md) | 제품 요구사항 — 목표, 범위, 로드맵, NFR, 성공 지표 |
| [기능 명세서](docs/FUNCTIONAL_SPEC.md) | 기능 ID, 수락 기준, 테스트 케이스, 단계별 DoD |
| [아키텍처](docs/architecture.md) | 3-Tier 네트워크·SG·라우팅·트래픽 흐름 상세 |
| [프로젝트 구조](docs/PROJECT_STRUCTURE.md) | Terraform 파일별 역할 및 완성 상태 |
| [1단계 개발 가이드](docs/STAGE_1_DEV_GUIDE.md) | Stage 1 구현 절차·체크리스트·트러블슈팅 |
| [Stage 1 Apply 런북](docs/STAGE_1_APPLY.md) | plan/apply/destroy 실무 절차 |
| [EKS 설계](docs/EKS_DESIGN.md) | EKS·IRSA·ECR·삭제 순서 |
| [k8s 매니페스트](k8s/README.md) | FE/BE Ingress 배포 가이드 |

**읽는 순서 권장:** PRD → 기능 명세서 → 아키텍처 → Stage 1 Apply → EKS 설계 → k8s

## 🏗️ 시스템 아키텍처

### 네트워크 구성

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC (10.0.0.0/16)                  │
├─────────────────────────────────────────────────────────────────┤
│  ap-northeast-2a (AZ-A)   │   ap-northeast-2c (AZ-C)            │
├──────────────────────────┬──────────────────────────────────────┤
│ Public Subnet            │  Public Subnet                       │
│ (10.0.1.0/24)            │  (10.0.2.0/24)                       │
│ ├─ Bastion Host          │  ├─ ALB                             │
│ └─ NAT Gateway + EIP     │  └─ NAT Gateway + EIP               │
│    (IGW는 VPC 공통)       │                                     │
├──────────────────────────┼──────────────────────────────────────┤
│ Private Web Subnet       │  Private Web Subnet                  │
│ (10.0.10.0/24)           │  (10.0.11.0/24)                      │
│ └─ EC2 Web Server (1)    │  └─ EC2 Web Server (2)               │
├──────────────────────────┼──────────────────────────────────────┤
│ Private DB Subnet        │  Private DB Subnet                   │
│ (10.0.20.0/24)           │  (10.0.21.0/24)                      │
│ └─ RDS 또는 DB 인스턴스   │  └─ RDS 또는 DB 인스턴스            │
└──────────────────────────┴──────────────────────────────────────┘
```

### 주요 특징
- ✅ **3-Tier 아키텍처**: Public/Web/DB 계층 분리 (서브넷 6개)
- ✅ **고가용성**: 2 AZ, NAT AZ별 1개(총 2), ALB 다중 타깃
- ✅ **보안**: 최소 권한 원칙(Least Privilege) 적용
- ✅ **비용 통제**: 테스트 후 `terraform destroy` (NAT·ALB 상시 과금 주의)

## 🚀 빠른 시작

### 1. 필수 사항
- AWS 계정 및 CLI 설치
- Terraform v1.5+
- Git

### 2. AWS 인증 설정
```bash
aws configure
# AWS Access Key ID, Secret Access Key 입력
# Default region: ap-northeast-2
```

### 3. 프로젝트 초기화
```bash
cd terraform
terraform init
```

### 4. 변수 설정
```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 본인의 공인 IP 주소를 terraform.tfvars에 입력
# my_ip = "YOUR_PUBLIC_IP/32"
```

### 5. 계획 검토
```bash
terraform plan
```

### 6. 인프라 배포
```bash
terraform apply
```

### 7. 배포 완료 후 정리 (테스트용)
```bash
terraform destroy
```

## 📁 디렉토리 구조

```
cicd/
├── README.md                          # 이 파일
├── .gitignore                         # Git 무시 설정
├── FE/                                # 프론트엔드 (정적 + Nginx Dockerfile)
│   ├── public/                        # HTML/CSS/JS
│   ├── nginx.conf
│   └── Dockerfile
├── BE/                                # 백엔드 (Node.js Express API)
│   ├── src/                           # server, routes, middleware
│   ├── tests/
│   ├── package.json
│   └── Dockerfile
├── k8s/                               # EKS 매니페스트 (FE/BE/Ingress)
│   ├── namespace.yaml
│   ├── fe/ be/ ingress/
│   └── aws-load-balancer-controller/
├── terraform/                         # Terraform (Stage 1 네트워크 + 선택 EKS)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── vpc.tf / subnets.tf / nat.tf / routing.tf / security_groups.tf
│   └── terraform.tfvars.example
├── docs/
│   ├── PRD.md                         # 제품 요구사항 (PRD v1.1, EKS 포함)
│   ├── FUNCTIONAL_SPEC.md             # 기능 명세서
│   ├── architecture.md
│   ├── PROJECT_STRUCTURE.md
│   ├── STAGE_1_DEV_GUIDE.md
│   ├── STAGE_1_APPLY.md               # Stage 1 apply 런북
│   └── EKS_DESIGN.md                  # EKS 설계
└── .github/
    └── workflows/                     # GitHub Actions (예정)
```

### 앱 로컬 실행 (요약)

**권장 — Docker Compose (FE+BE 통합, same-origin)**

```bash
docker compose up --build
# FE  http://localhost:8080
# BE  http://localhost:3000/health
# 브라우저에서 /health, /api/hello 자동 호출 확인
```

**개별 실행**

```bash
# Backend
cd BE && npm ci && npm run dev

# Frontend only (config.js 의 API_BASE_URL 을 http://localhost:3000 으로)
cd FE && python3 -m http.server 8080 --directory public
```

## 📊 [1단계] Terraform 인프라 코드화

### 구현 범위
- ✅ VPC 및 Internet Gateway
- ✅ Public/Private 서브넷 **6개** (Public 2 + Web 2 + DB 2)
- ✅ NAT Gateway **2** + Elastic IP **2** (AZ별)
- ✅ 라우팅 테이블 **5개** (Public 1 + Web AZ별 2 + DB AZ별 2)
- ✅ 보안 그룹 4개 (ALB / Web / Bastion / RDS)

### 완료 기준
- [ ] `terraform validate` 통과
- [ ] `terraform plan` 산출물 검토 완료
- [ ] 주요 리소스 6개 이상 생성 예정
- [ ] 문서화 완성

## 🔐 보안 고려사항

1. **AWS 인증 정보 보안**
   - `terraform.tfvars` 파일은 Git에 커밋하지 않음
   - `.gitignore`에 `*.tfvars` 추가 (기본 설정됨)
   - GitHub Secrets를 활용한 안전한 CI/CD

2. **최소 권한 원칙**
   - Bastion: 개발자 IP만 SSH 접속 허용
   - Web EC2: ALB로부터의 트래픽만 허용
   - DB: Web 계층으로부터만 접속 허용

3. **State 파일 관리**
   - 초기: 로컬 `terraform.tfstate` 사용
   - 향후: S3 + DynamoDB Remote State로 전환 권장

## 📝 주요 명령어

```bash
# Terraform 초기화
terraform init

# 코드 포맷 정리
terraform fmt -recursive

# 문법 검사
terraform validate

# 변경 사항 미리보기
terraform plan

# 실제 배포
terraform apply

# 리소스 삭제
terraform destroy

# 상태 파일 확인
terraform state list
terraform state show aws_vpc.main
```

## 🔄 진행 단계

| 단계 | 기간 | 목표 | 상태 |
|------|------|------|------|
| 1단계 | 1~2주 | Terraform 네트워크 IaC (NAT 2·RT 5) | 🔴 진행중 |
| 2단계 | ~1주 | Bastion (레거시 EC2 웹은 선택 P2) | ⚪ 예정 |
| 3단계 | ~1주 | GitHub Actions (fmt/validate/plan) | ⚪ 예정 |
| 4단계 | ~1–2주 | **EKS + Ingress 앱 + (P1) ECR/CD** | ⚪ 예정 |

상세 범위·성공 기준: [docs/PRD.md](docs/PRD.md) §14 EKS 확장

## 💡 학습 포인트

이 프로젝트를 통해 습득할 수 있는 역량:
- ✅ AWS 네트워크 아키텍처 설계
- ✅ Terraform을 이용한 IaC 작성
- ✅ 고가용성 및 보안을 고려한 인프라 구축
- ✅ GitHub Actions 기반 CI/CD 파이프라인
- ✅ DevOps 기본 개념 및 실무 경험

## 📖 외부 참고 자료

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS VPC 개념 가이드](https://docs.aws.amazon.com/vpc/)
- [GitHub Actions 가이드](https://docs.github.com/actions)

프로젝트 내부 문서는 위의 [프로젝트 문서](#-프로젝트-문서) 섹션을 참고하세요.

## 📞 문의 및 피드백

이 프로젝트에 대한 개선사항이나 버그는 Issues에 등록해주세요.

---

**마지막 업데이트**: 2026-07-16  
**버전**: v0.2.0 (PRD v1.1 — EKS 권장 A 범위 추가)
