# IaC 기반 클라우드 네트워크 자동화 및 CI/CD 파이프라인

[![BE CI](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/be-ci.yml/badge.svg)](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/be-ci.yml)
[![Docker Build](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/docker-build.yml/badge.svg)](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/docker-build.yml)
[![Integration](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/integration.yml/badge.svg)](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/integration.yml)
[![Terraform CI](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/terraform-ci.yml)
[![CI Auth](https://img.shields.io/badge/CI_Auth-OIDC-0A7B3E?logo=amazon-aws&logoColor=white)](docs/OIDC_SETUP.md)
[![Cost](https://img.shields.io/badge/Default-Free_mode-2ea44f)](docs/FREE_MODE.md)
[![Infra](https://img.shields.io/badge/AWS_infra-destroyed-6c757d)](docs/DEMO_E2E_RESULT.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Terraform**으로 3-Tier 보안 네트워크를 코드화하고, **Amazon EKS** 위에 FE/BE를 올려 **ALB Ingress**로 서비스하며, **GitHub Actions(OIDC plan)** 로 검증하는 포트폴리오 프로젝트입니다.

### 3줄 요약 (문제 → 설계 → 결과)

| | |
|--|--|
| **문제** | 콘솔 수동 인프라는 재현이 어렵고, CI 장기 Access Key·상시 NAT/EKS는 보안·비용 리스크가 크다. |
| **설계** | Terraform 2-AZ 3-Tier · Bastion/SSM · EKS(ALB Ingress) · 평소 Docker 무료 · 유료 이중 확인 apply·destroy · CI는 **GitHub OIDC** plan Role. |
| **결과** | ALB `/` `/health` `/api/*` **HTTP 200 E2E** 후 **destroy**. Access Key Secret 제거 · **OIDC main-only trust** plan 성공 · 자동화 apply 차단. |

📄 [이력서 1p](docs/RESUME_ONE_PAGER.md) · 📓 [노션 가이드](docs/NOTION_GUIDE.md) · 🎬 [데모 시각자료](docs/demo/README.md) · 🔐 [OIDC](docs/OIDC_SETUP.md)

> ### 💰 기본은 무료 모드 · 유료는 **본인 확인 필수**
>
> - 일상 개발: **`./scripts/dev-free.sh`** (Docker만, 과금 없음)
> - NAT/EKS/Bastion 등 **유료 apply** 는 아래를 **모두** 만족할 때만 가능:
>   1. `acknowledge_paid_aws = true`
>   2. `confirm_paid_apply = "YES_I_ACCEPT_AWS_CHARGES"` (사용자 동의 문구)
>   3. 권장: `./scripts/terraform-apply-paid.sh` (입력 확인)
> - **AI/자동화는 사용자 추가 승인 없이 유료 apply 금지** ([AGENTS.md](AGENTS.md))
> - 가이드: [docs/FREE_MODE.md](docs/FREE_MODE.md)

| 항목 | 내용 |
|------|------|
| 리전 | `ap-northeast-2` (서울) |
| IaC | Terraform ≥ 1.5 |
| 앱 | `FE/` (Nginx 정적) · `BE/` (Node.js Express) |
| 오케스트레이션 | Amazon EKS (선택 활성화 · 현재 destroy) |
| CI | GitHub Actions — test / docker / integration / **TF plan via OIDC** |
| 인증 | Secret `AWS_ROLE_ARN` only (장기 키 Secret 없음) |
| 저장소 | [github.com/jinhgit/cloud-infra-cicd](https://github.com/jinhgit/cloud-infra-cicd) |

---

## 현재 상태 · 데모 (한눈에)

| 항목 | 상태 |
|------|------|
| **평소 개발** | 무료 — `./scripts/dev-free.sh` → http://localhost:8080 |
| **유료 AWS** | 기본 OFF · 이중 확인 없으면 apply 불가 |
| **EKS E2E** | 실전 성공 (ALB 200) → [DEMO_E2E_RESULT](docs/DEMO_E2E_RESULT.md) → **destroy** |
| **인프라 현재** | 비움 (과금 리소스 없음) |
| **CI Auth** | **OIDC** plan Role · main 브랜치 only · Access Key Secret 삭제 |
| **CI 잡** | BE test · Docker amd64 · Compose 통합 · TF fmt/validate/**plan** |

### 시각 자료 (표지 추천 순서 · [전체 설명](docs/demo/README.md))

| Free / CI / Paid 한 장 | OIDC plan 흐름 |
|------------------------|----------------|
| ![modes](docs/demo/screenshots/06-modes-overview.jpg) | ![oidc](docs/demo/screenshots/05-oidc-flow.jpg) |

| 트래픽 경로 (ALB→Pods) | EKS E2E curl 200 |
|------------------------|------------------|
| ![arch](docs/demo/screenshots/04-architecture-path.jpg) | ![E2E](docs/demo/screenshots/03-eks-e2e-terminal.png) |

| 로컬 UI (과금 0) | lab · 무료/유료 안내 |
|------------------|----------------------|
| ![로컬 홈](docs/demo/screenshots/01-local-home.png) | ![lab](docs/demo/screenshots/02-local-lab.png) |

| 자료 | 링크 |
|------|------|
| 데모 세트 · 60초 스크립트 | [docs/demo/README.md](docs/demo/README.md) |
| 이력서 3줄 · 성과 불릿 | [docs/RESUME_ONE_PAGER.md](docs/RESUME_ONE_PAGER.md) |
| 노션 복붙 | [docs/NOTION_GUIDE.md](docs/NOTION_GUIDE.md) |
| 로컬 지금 바로 | `./scripts/dev-free.sh` → http://localhost:8080 |

---

## 목차

1. [현재 상태 · 데모](#현재-상태--데모-한눈에)
2. [한눈에 보는 아키텍처](#한눈에-보는-아키텍처)
3. [데모 시나리오](#데모-시나리오)
4. [빠른 시작](#빠른-시작)
5. [디렉터리 구조](#디렉터리-구조)
6. [진행 단계](#진행-단계)
7. [프로젝트 문서](#프로젝트-문서)
8. [보안·비용](#보안비용)

---

## 한눈에 보는 아키텍처

### 전체 구성 (권장 A — EKS)

```mermaid
flowchart TB
  subgraph Internet["Internet"]
    User["사용자 / 브라우저"]
    Dev["개발자"]
    GH["GitHub Actions"]
  end

  subgraph AWS["AWS ap-northeast-2"]
    subgraph VPC["VPC 10.0.0.0/16"]
      IGW["Internet Gateway"]

      subgraph Public["Public Subnets ×2 AZ"]
        ALB["ALB\n(AWS LB Controller)"]
        NAT["NAT Gateway ×2\n(AZ별)"]
        Bastion["Bastion (선택)"]
      end

      subgraph PrivateWeb["Private Web ×2 AZ"]
        Nodes["EKS Worker Nodes"]
        Pods["Pods: FE · BE"]
      end

      subgraph PrivateDB["Private DB ×2 AZ"]
        DB["RDS 공간\n(선택)"]
      end

      EKS["EKS Control Plane"]
    end

    ECR["Amazon ECR\nFE / BE 이미지"]
  end

  User -->|"HTTP :80"| IGW --> ALB
  ALB -->|"Ingress 경로"| Pods
  Pods --> Nodes
  Nodes -->|"outbound"| NAT --> IGW
  EKS --- Nodes
  Dev -->|"SSH my_ip"| Bastion
  Dev -->|"kubectl / API"| EKS
  GH -->|"plan / test"| AWS
  Nodes -->|"image pull"| ECR
  Pods -.->|"선택 3306"| DB
```

### 트래픽 경로 (런타임)

```mermaid
sequenceDiagram
  participant U as 사용자
  participant ALB as ALB (Public)
  participant FE as FE Pod
  participant BE as BE Pod

  U->>ALB: GET /
  ALB->>FE: path /
  FE-->>U: HTML/CSS/JS

  U->>ALB: GET /health
  ALB->>BE: path /health
  BE-->>U: {"status":"ok"}

  U->>ALB: GET /api/hello
  ALB->>BE: path /api/hello
  BE-->>U: {"message":"Hello from BE"}
```

| 경로 | 대상 | 용도 |
|------|------|------|
| `/` | FE Service | 데모 UI |
| `/health` | BE Service | API 헬스 (ALB·FE 호출) |
| `/api/*` | BE Service | REST API |
| FE `/healthz` | FE 컨테이너 | K8s probe (클러스터 내부) |

### 네트워크 계층 (Stage 1)

```mermaid
flowchart LR
  subgraph AZ_A["ap-northeast-2a"]
    PubA["Public\n10.0.1.0/24\nNAT-A"]
    WebA["Private Web\n10.0.10.0/24"]
    DbA["Private DB\n10.0.20.0/24"]
  end
  subgraph AZ_C["ap-northeast-2c"]
    PubC["Public\n10.0.2.0/24\nNAT-C"]
    WebC["Private Web\n10.0.11.0/24"]
    DbC["Private DB\n10.0.21.0/24"]
  end
  WebA -->|"0.0.0.0/0"| PubA
  WebC -->|"0.0.0.0/0"| PubC
  DbA -.->|"인터넷 경로 없음"| DbA
  DbC -.->|"인터넷 경로 없음"| DbC
```

| 항목 | 값 |
|------|-----|
| VPC | `10.0.0.0/16` |
| 서브넷 | **6** (Public 2 + Web 2 + DB 2) |
| NAT / EIP | **AZ당 1 = 2** |
| Route Table | **5** (Public 1 + Web AZ별 2 + DB AZ별 2) |
| SG | ALB · Web · Bastion · RDS |

ASCII 상세도는 [docs/architecture.md](docs/architecture.md) 참고.

### CI/CD 흐름

```mermaid
flowchart LR
  subgraph Dev["개발"]
    Code["git push / PR"]
  end
  subgraph Actions["GitHub Actions"]
    BECI["BE CI\nnpm test"]
    TFCheck["Terraform CI\nfmt + validate"]
    TFPlan["terraform plan\nOIDC · main only"]
  end
  subgraph Manual["수동 · 데모 당일"]
    Apply["terraform apply\nenable_eks=true"]
    Deploy["ECR push + kubectl"]
    Destroy["terraform destroy"]
  end

  Code --> BECI
  Code --> TFCheck --> TFPlan
  Apply --> Deploy --> Destroy
```

- **CI는 apply 하지 않음** (과금·안전).  
- 설정: [docs/CI.md](docs/CI.md)

---

## 데모 시나리오

포트폴리오/발표용으로 **두 가지 시나리오**를 준비했습니다.

### 시나리오 A — 로컬 앱 데모 (비용 0, 5분)

**증명 포인트:** FE/BE same-origin 연동, Docker 이미지, 헬스 API

```bash
# 1) 저장소 클론 후
docker compose up --build

# 2) 브라우저
open http://localhost:8080
# 또는
curl -sS http://localhost:8080/health
curl -sS http://localhost:8080/api/hello

# 3) 종료
docker compose down
```

| 확인 | 기대 |
|------|------|
| UI Backend Health | OK (200) |
| UI GET /api/hello | OK (200) |
| `BE` `npm test` | 3 passed |

```mermaid
flowchart LR
  Browser["브라우저 :8080"] --> FE["FE 컨테이너\nNginx"]
  FE -->|"proxy /health /api"| BE["BE 컨테이너\n:3000"]
```

---

### 시나리오 B — AWS EKS E2E 데모 (과금 있음, 2.5~4시간)

**증명 포인트:** 3-Tier 네트워크 · EKS · ALB Ingress · ECR · destroy 수명주기

> **전체 명령·체크박스:** [docs/EKS_E2E_CHECKLIST.md](docs/EKS_E2E_CHECKLIST.md)  
> 아래는 발표용 **요약 스크립트**입니다.

#### B-1. 인프라 기동

```bash
cd terraform
# terraform.tfvars: my_ip = "현재공인IP/32", enable_eks = true
terraform init
terraform plan -out=tfplan
terraform apply tfplan

export AWS_REGION=ap-northeast-2
export CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
kubectl get nodes   # Ready ≥ 2
```

#### B-2. Controller · 이미지 · 앱

```bash
# LB Controller: k8s/aws-load-balancer-controller/install.md
# ECR 로그인 후
docker build -t "$(terraform output -json ecr_repository_urls | jq -r .be):latest" ../BE
docker build -t "$(terraform output -json ecr_repository_urls | jq -r .fe):latest" ../FE
docker push ...   # E2E 체크리스트 §3 참고

# 매니페스트 IMAGE_* 치환 후
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/be/ -f k8s/fe/ -f k8s/ingress/
kubectl -n cloud-infra get ingress cloud-infra   # ADDRESS = ALB DNS
```

#### B-3. 성공 판정 (발표 시 보여줄 것)

```bash
export ALB_DNS=$(kubectl -n cloud-infra get ingress cloud-infra \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -sS -o /dev/null -w "%{http_code}\n" "http://${ALB_DNS}/"          # 200
curl -sS "http://${ALB_DNS}/health"                                      # status ok
curl -sS "http://${ALB_DNS}/api/hello"                                   # Hello from BE
# 브라우저: http://$ALB_DNS/
```

| 데모 체크 | 통과 기준 |
|-----------|-----------|
| 노드 | Ready ≥ 2, Private 서브넷 |
| Ingress | ALB DNS 할당 |
| `/` | FE HTML 200 |
| `/health`, `/api/hello` | BE JSON 200 |
| 보안 스토리 | 노드 공인 직접 접속 없음, Bastion은 `my_ip`만 (구현 시) |

#### B-4. 비용 차단 (발표 직후 필수)

```bash
kubectl delete -f k8s/ingress/ --ignore-not-found   # ALB 정리 대기
helm uninstall aws-load-balancer-controller -n kube-system || true
cd terraform && terraform destroy -auto-approve
# NAT / EKS / ALB 잔존 여부 콘솔·CLI 재확인 (E2E 체크리스트 §6)
```

```mermaid
flowchart TB
  subgraph DemoDay["데모 당일 타임라인"]
    T0["0. 로컬 Compose 스모크"] --> T1["1. TF apply EKS"]
    T1 --> T2["2. LB Controller"]
    T2 --> T3["3. ECR push"]
    T3 --> T4["4. kubectl apply"]
    T4 --> T5["5. curl / 브라우저"]
    T5 --> T6["6. destroy ★필수"]
  end
```

---

### 시나리오 비교

| | A. 로컬 | B. AWS EKS |
|--|---------|------------|
| 비용 | 없음 | NAT·EKS·노드·ALB (시간 과금) |
| 시간 | ~5분 | 2.5~4시간 |
| 증명 | 앱·Docker·API | 네트워크+EKS+Ingress+수명주기 |
| CI 연관 | `BE CI` 로컬과 동일 테스트 | `Terraform CI` plan 과 코드 동일 |

---

## 빠른 시작

### 필수 도구

- AWS CLI, Terraform ≥ 1.5, Git  
- 앱/EKS 데모: Docker, kubectl, Helm  

### 로컬 앱 (시나리오 A) — **추천 · 과금 0**

```bash
./scripts/dev-free.sh
# 또는: docker compose up --build
# http://localhost:8080          — API · 버전/gitSha
# http://localhost:8080/lab.html — 체크리스트 · 무료/유료 안내

./scripts/integration-test.sh    # Compose curl 자동 검증
./scripts/build-images.sh        # linux/amd64 로컬 빌드 (푸시 없음)
make check                       # fmt + validate + BE test
```

### Terraform (네트워크만, EKS 끔)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# my_ip 수정 / enable_eks = false 유지
terraform init
terraform plan
terraform apply
# 끝나면
terraform destroy
```

런북: [docs/STAGE_1_APPLY.md](docs/STAGE_1_APPLY.md)

### CI 로컬 동일 검사

```bash
cd BE && npm ci && npm test
cd terraform && terraform fmt -check -recursive \
  && terraform init -backend=false && terraform validate
```

---

## 디렉터리 구조

```
cloud-infra-cicd/
├── README.md · AGENTS.md · CHANGELOG.md · CONTRIBUTING.md
├── docker-compose.yml · scripts/
│   ├── dev-free.sh · verify-lab.sh
│   ├── build-images.sh · build-push-images.sh
│   ├── render-k8s-images.sh · deploy-k8s.sh
│   ├── integration-test.sh
│   └── terraform-apply-paid.sh · terraform-destroy-paid.sh
├── FE/ · BE/ · k8s/ · terraform/ · docs/
└── .github/workflows/        # be · docker-build · integration · terraform
```

---

## 진행 단계

| 단계 | 목표 | 상태 |
|------|------|------|
| 1 | Terraform 네트워크 (NAT 2 · RT 5 · SG) | ✅ |
| 2 | Bastion SSH/SSM | ✅ |
| 3 | GitHub Actions (test/build/plan/PR 코멘트) | ✅ |
| 4 | EKS + Ingress E2E (실전 성공 이력) | ✅ (재현 시 유료 동의) |
| — | 무료 모드 가드 · 배포 스크립트 · 통합 테스트 | ✅ |

상세: [docs/PRD.md](docs/PRD.md)

---

## 프로젝트 문서

| 문서 | 설명 |
|------|------|
| [PRD](docs/PRD.md) | 목표, 범위, EKS §14 |
| [기능 명세서](docs/FUNCTIONAL_SPEC.md) | 기능 ID · 수락 기준 |
| [architecture](docs/architecture.md) | 네트워크 상세 |
| [STAGE_1_APPLY](docs/STAGE_1_APPLY.md) | 네트워크 apply 런북 |
| [BASTION](docs/BASTION.md) | Bastion SSH / SSM 접속 |
| [**데모 스크린샷 세트**](docs/demo/README.md) | 로컬 UI + E2E 기록 (채용관용) |
| [**이력서 1페이지**](docs/RESUME_ONE_PAGER.md) | 복붙용 성과·문장 |
| [**면접 Q&A · Lessons**](docs/INTERVIEW_QA_LESSONS.md) | 면접 준비 |
| [**OIDC 실전 설정**](docs/OIDC_SETUP.md) | 계정 `447170313588` 맞춤 |
| [**노션 정리 가이드**](docs/NOTION_GUIDE.md) | 노션 페이지 트리·복붙 템플릿 |
| [**무료 모드**](docs/FREE_MODE.md) | 과금 없이 개발하는 기본 경로 |
| [**실습 확인 가이드**](docs/LAB_VERIFY.md) | 콘솔·CLI·FE로 상태 확인 |
| [EKS_DESIGN](docs/EKS_DESIGN.md) | EKS 설계 |
| [**EKS_E2E_CHECKLIST**](docs/EKS_E2E_CHECKLIST.md) | **데모 당일 전체 명령** |
| [CI](docs/CI.md) | Actions · Secrets |
| [k8s README](k8s/README.md) | 매니페스트 |

---

## 보안·비용

### 보안

- `terraform.tfvars` / `*.tfstate` / `.env` → Git 제외  
- Bastion·EKS API: `my_ip` 제한 권장  
- CI: **GitHub OIDC** → IAM plan Role (main only) · Access Key Secret 없음 ([OIDC_SETUP](docs/OIDC_SETUP.md) · [CI](docs/CI.md))  
- 최소 권한 SG (ALB → 워크로드, DB → Web SG만)

### 비용

| 리소스 | 주의 |
|--------|------|
| NAT ×2 | 상시 과금 |
| EKS 컨트롤 플레인 | **클러스터 유지 시간** 과금 (노드 0이어도) |
| 노드 EC2 · ALB | 데모 중 과금 |
| **대응** | 데모 후 **즉시 destroy** + 잔존 ALB/NAT 점검 · 평소는 free mode |

---

## 학습 포인트

- AWS 3-Tier · 2-AZ 네트워크 설계  
- Terraform IaC · plan/apply/destroy 수명주기  
- EKS · IRSA · ALB Ingress  
- 컨테이너 FE/BE · ECR  
- GitHub Actions CI + **OIDC**  
- 비용 가드 · destroy 운영  

## 포트폴리오 마감 체크

| 항목 | 상태 |
|------|------|
| 3줄 요약 (문제→설계→결과) | [RESUME_ONE_PAGER](docs/RESUME_ONE_PAGER.md) · [NOTION_GUIDE](docs/NOTION_GUIDE.md) |
| README 배지 + 데모 시각 6장 | 본 문서 상단 · [demo](docs/demo/README.md) |
| OIDC plan · Access Key Secret 삭제 | 완료 |
| OIDC trust main-only | 완료 |
| 인프라 destroy | 완료 (재데모 시 paid 스크립트) |
| 로컬 CLI IAM Access Key (JHM) | 유지 (로컬 작업용 · CI 아님) |

## 참고 링크

- [Terraform](https://www.terraform.io/docs) · [AWS VPC](https://docs.aws.amazon.com/vpc/) · [EKS](https://docs.aws.amazon.com/eks/) · [GitHub Actions](https://docs.github.com/actions) · [GitHub OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

**마지막 업데이트:** 2026-07-17  
**버전:** v0.4.0 — P1/P2 스크립트·CI 고도화 · 무료 가드 · 데모 요약
