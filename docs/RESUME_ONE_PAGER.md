# 이력서·포트폴리오 원페이지

> 노션/이력서에 **복사**하거나 PDF 1장으로 쓸 요약본입니다.  
> 저장소: https://github.com/jinhgit/cloud-infra-cicd  
> **상태:** 포트폴리오 마감 (인프라 destroy · CI는 OIDC plan · 평소 무료 Docker)

---

## 3줄 요약 (고정 · 문제 → 설계 → 결과)

| # | 축 | 문장 (복붙) |
|---|-----|-------------|
| 1 | **문제** | 콘솔 수동 인프라는 재현이 어렵고, CI 장기 Access Key·상시 NAT/EKS는 보안·비용 리스크가 크다. |
| 2 | **설계** | Terraform으로 2-AZ 3-Tier·Bastion/SSM·EKS(ALB Ingress)를 코드화하고, 평소는 Docker 무료 개발·유료는 이중 확인 apply·즉시 destroy, CI plan 은 GitHub OIDC Role 로만 수행. |
| 3 | **결과** | ALB `/`·`/health`·`/api/*` **HTTP 200 E2E** 검증 후 **destroy**로 과금 제로화. GitHub Secrets 장기 키 제거, **OIDC + main-only trust** 로 `terraform plan` 성공, `acknowledge_paid_aws` + 확인 문구 가드로 자동화 apply 차단. |

### 30초 말하기 (면접)

> “수동 인프라·장기 키·상시 과금 문제를, Terraform 3-Tier/EKS와 무료 기본·이중 확인·destroy, 그리고 GitHub OIDC plan 으로 정리했습니다. 데모 날 ALB 200을 찍고 인프라는 비운 상태입니다.”

---

## 프로젝트 한 줄

**Terraform 기반 3-Tier AWS 네트워크 + Bastion/SSM + EKS(ALB Ingress) + GitHub Actions (OIDC plan)**  
평소는 Docker로 무과금 개발, 클라우드 유료 리소스는 이중 확인 후 짧은 데모·즉시 destroy.

---

## 역할 / 기간

| 항목 | 내용 |
|------|------|
| 역할 | 설계 · IaC · 앱 컨테이너 · CI · 문서 (1인) |
| 스택 | AWS, Terraform, EKS, ALB, ECR, VPC, GitHub Actions OIDC, Docker, Node.js, Nginx |
| 리전 | ap-northeast-2 |
| CI 인증 | **OIDC** (`AWS_ROLE_ARN` only · Access Key Secret 없음) |

---

## 핵심 성과 (불릿 · 이력서 복붙용)

- **2-AZ 3-Tier VPC**를 Terraform으로 코드화 (Public/Web/DB 서브넷 6, NAT·RT·SG 최소 권한)
- **Bastion** 구축 (SSH my_ip 제한 + **SSM Session Manager**, IMDSv2, 암호화 볼륨)
- **EKS 1.32** Managed Node (Private) + **AWS LB Controller(IRSA)** 로 Ingress → **ALB** 경로 검증  
  (`/` FE, `/health`·`/api/*` BE, HTTP 200 E2E 성공 → **destroy**)
- FE/BE **Docker**화, same-origin API, health/version/gitSha, Compose 통합 테스트
- GitHub Actions: **test · amd64 이미지 빌드 · Compose 통합 · terraform fmt/validate/plan**
- **GitHub OIDC → IAM plan Role (ReadOnly)** — 장기 Access Key Secret 제거, trust는 **main 브랜치 only**
- **비용·보안 가드**: `acknowledge_paid_aws` + `confirm_paid_apply` 이중 확인, AI/자동화 apply 금지, 기본 무료 모드
- 실전 이슈: EKS 버전, Free Tier 인스턴스, **linux/amd64**, LB Controller IAM, **OIDC sub 클레임(ID 포함 형식)** CloudTrail 추적

---

## 아키텍처 (텍스트)

```text
Internet → ALB (Public) → Ingress → FE/BE Pods (Private Nodes)
Developer → Bastion (SSH/SSM)
CI → GitHub Actions OIDC → IAM Role → terraform plan (no apply)
Daily → Docker Compose (zero AWS cost)
Demo day → dual-confirm apply → verify 200 → destroy
```

스크린샷·다이어그램: [docs/demo/README.md](demo/README.md)

---

## 기술 키워드 (ATS/검색)

`AWS` `Terraform` `VPC` `NAT Gateway` `Security Group` `EKS` `ALB` `Ingress` `IRSA`  
`ECR` `Bastion` `SSM` `GitHub Actions` `OIDC` `Docker` `CI/CD` `IaC` `Least Privilege` `Cost Control`

---

## 링크

| 구분 | URL |
|------|-----|
| GitHub | https://github.com/jinhgit/cloud-infra-cicd |
| 데모 세트 (시각자료) | [docs/demo/README.md](demo/README.md) |
| E2E 결과 | [DEMO_E2E_RESULT.md](DEMO_E2E_RESULT.md) |
| 무료 모드 | [FREE_MODE.md](FREE_MODE.md) |
| 면접 Q&A | [INTERVIEW_QA_LESSONS.md](INTERVIEW_QA_LESSONS.md) |
| OIDC 설정 | [OIDC_SETUP.md](OIDC_SETUP.md) |
| 노션 가이드 | [NOTION_GUIDE.md](NOTION_GUIDE.md) |

---

## 이력서 문장 예시 (완성형)

> AWS 서울 리전에서 Terraform으로 다중 AZ 3-Tier 네트워크와 Bastion을 구성하고, EKS Private 노드 위 FE/BE 워크로드를 ALB Ingress로 노출하는 경로를 E2E 검증한 뒤 인프라를 destroy 해 상시 과금을 제거함. GitHub Actions는 OIDC로 IAM plan Role을 引き受け terraform plan만 수행하고, 유료 리소스는 이중 확인 문구 없이는 apply 되지 않도록 비용 통제 체계를 적용함.

---

## 면접 시 강조 3가지

1. **설계 이유** — Private 노드, SG, NAT HA vs 비용, plan-only CI  
2. **실전 트러블슈팅** — EKS 버전·플랫폼·IRSA·**OIDC sub(ID 형식) CloudTrail**  
3. **운영 의식** — 무료 기본, 유료 이중 확인, E2E 후 destroy, 장기 키 제거  
