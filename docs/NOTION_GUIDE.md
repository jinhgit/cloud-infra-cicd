# 노션 정리 가이드

이 저장소 문서를 **노션 포트폴리오 페이지**로 옮길 때 쓰는 템플릿입니다.  
아래 블록을 노션에 복사한 뒤, 링크만 GitHub raw/blob URL로 바꾸면 됩니다.

**프로젝트 상태:** 마감 · OIDC plan 적용 완료 · Access Key Secret 삭제 · 인프라 destroy

---

## 0. 표지용 3줄 요약 (고정 · 최상단 고정 추천)

> 노션 표지·이력서·면접 카드에 **항상 이 3줄**을 씁니다.  
> 원본: [RESUME_ONE_PAGER.md](RESUME_ONE_PAGER.md)

| # | 축 | 문장 |
|---|-----|------|
| 1 | **문제** | 콘솔 수동 인프라는 재현이 어렵고, CI 장기 Access Key·상시 NAT/EKS는 보안·비용 리스크가 크다. |
| 2 | **설계** | Terraform으로 2-AZ 3-Tier·Bastion/SSM·EKS(ALB Ingress)를 코드화하고, 평소는 Docker 무료 개발·유료는 이중 확인 apply·즉시 destroy, CI plan 은 GitHub OIDC Role 로만 수행. |
| 3 | **결과** | ALB `/`·`/health`·`/api/*` **HTTP 200 E2E** 검증 후 **destroy**로 과금 제로화. GitHub Secrets 장기 키 제거, **OIDC + main-only trust** 로 `terraform plan` 성공, 이중 확인 가드로 자동화 apply 차단. |

### 30초 스크립트 (토글)

```text
수동 인프라·장기 키·상시 과금 문제를,
Terraform 3-Tier/EKS + 무료 기본·이중 확인·destroy + GitHub OIDC plan 으로 정리했습니다.
데모 날 ALB 200을 찍고 인프라는 비운 상태입니다.
```

---

## 1. 권장 노션 구조 (페이지 트리)

```text
📁 포트폴리오
└── 📄 Cloud Infra CI/CD (대표 프로젝트)
    ├── 📄 01. 한 줄 소개 · 3줄 요약 · 성과 (← RESUME_ONE_PAGER)
    ├── 📄 02. 아키텍처 · 데모 스크린샷 (← demo/)
    ├── 📄 03. 기술 스택 · 링크 · CI 배지
    ├── 📄 04. 면접 Q&A · Lessons (← INTERVIEW_QA_LESSONS)
    ├── 📄 05. 비용·무료 모드 (← FREE_MODE 요약)
    ├── 📄 06. OIDC (적용 완료) (← OIDC_SETUP 요약)
    └── 📄 07. 회고 · 마감 체크
```

---

## 2. 표지 페이지 (복붙용)

### 제목
`[Project] IaC 3-Tier + EKS + GitHub Actions OIDC`

### 한 줄
Terraform으로 AWS 네트워크·Bastion·EKS(ALB Ingress)를 코드화하고, 평소는 Docker로 무과금 개발·유료 클라우드는 이중 확인 후 짧은 데모·destroy. CI plan 은 OIDC.

### 배지/링크
- GitHub: https://github.com/jinhgit/cloud-infra-cicd  
- Actions (Terraform CI): https://github.com/jinhgit/cloud-infra-cicd/actions/workflows/terraform-ci.yml  
- 데모 세트: https://github.com/jinhgit/cloud-infra-cicd/blob/main/docs/demo/README.md  
- 원페이지: https://github.com/jinhgit/cloud-infra-cicd/blob/main/docs/RESUME_ONE_PAGER.md  

### 커버용 이미지 (노션에 업로드 · 순서 권장)

| 순서 | 파일 | 설명 (캡션으로 붙이기) |
|------|------|------------------------|
| 1 | `06-modes-overview.jpg` | Free / OIDC CI / Paid demo → destroy 한눈에 |
| 2 | `05-oidc-flow.jpg` | GitHub JWT → OIDC Provider → Role → plan only |
| 3 | `04-architecture-path.jpg` | Internet → ALB → Private Pods |
| 4 | `01-local-home.png` | 로컬 데모 UI (과금 0) |
| 5 | `03-eks-e2e-terminal.png` | EKS E2E curl 200 증거 |

**raw URL 예:**

```text
https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/06-modes-overview.jpg
https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/05-oidc-flow.jpg
https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/04-architecture-path.jpg
https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/01-local-home.png
https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/03-eks-e2e-terminal.png
```

---

## 3. 노션 데이터베이스 (선택) — “프로젝트 카드”

| 속성 | 타입 | 예시 값 |
|------|------|---------|
| Name | Title | Cloud Infra CI/CD |
| Role | Select | Cloud / DevOps |
| Stack | Multi-select | AWS, Terraform, EKS, Actions, OIDC |
| Status | Select | **Closed / Portfolio-ready** |
| Cost | Select | Free-by-default |
| Auth | Select | OIDC (no long-lived CI keys) |
| GitHub | URL | https://github.com/jinhgit/cloud-infra-cicd |
| Highlight | Text | E2E ALB 200 + OIDC plan + destroy |

---

## 4. 페이지별 채울 내용 (체크)

### 01. 한 줄 소개 · 성과
- [x] **3줄 요약** (본 문서 §0)  
- [x] `RESUME_ONE_PAGER.md` 핵심 성과 불릿  
- [x] 이력서 문장 1개  
- [x] 면접 강조 3가지  

### 02. 아키텍처 · 데모
- [x] 스크린샷 6장 갤러리 (`docs/demo/`)  
- [x] 30초 발표 스크립트  
- [x] “라이브 URL 없음 = 비용 설계(destroy)” 한 줄  

### 03. 기술 스택 · 링크
- [x] 키워드 나열  
- [x] GitHub Actions 배지 (초록 = CI 통과)  

### 04. 면접 Q&A
- [ ] `INTERVIEW_QA_LESSONS.md` 에서 Q1~Q5 암기  
- [x] Lessons 표 (버전·플랫폼·IRSA·OIDC sub)  

### 05. 비용
- [x] 무료: `dev-free.sh`  
- [x] 유료: 이중 확인 문구  
- [x] destroy 습관  

### 06. OIDC
- [x] Provider + Role (ReadOnly) + `AWS_ROLE_ARN`  
- [x] `id-token: write` · main-only trust  
- [x] plan 성공 · Access Key Secret 삭제  
- [x] 적용 여부: **적용 완료**  

### 07. 회고 · 마감
- [x] 잘한 것: IaC E2E, 비용 가드, OIDC 전환  
- [ ] (선택 학습) remote state, 관측, NetworkPolicy  

---

## 5. 노션 토글 템플릿 (면접 준비)

```text
▶ 30초 소개 (3줄 요약)
▶ 왜 Private 노드? / IRSA?
▶ 비용 어떻게 막았나? (이중 확인 + destroy)
▶ OIDC vs Access Key (sub 클레임 CloudTrail 경험)
▶ 실패 경험 (EKS 버전, amd64, IAM 정책, OIDC sub)
```

---

## 6. GitHub → 노션 링크 팁

- 문서: `https://github.com/jinhgit/cloud-infra-cicd/blob/main/docs/파일명.md`  
- 이미지: raw URL (위 §2)  
- 노션 이미지 블록에 raw URL 붙이면 README와 동기화 가능  

---

## 7. 이 저장소 문서 맵 (노션 목차용)

| 노션 섹션 | 파일 |
|-----------|------|
| 3줄·이력서 1p | [RESUME_ONE_PAGER.md](RESUME_ONE_PAGER.md) |
| 시각 데모 | [demo/README.md](demo/README.md) |
| OIDC | [OIDC_SETUP.md](OIDC_SETUP.md) |
| 면접 | [INTERVIEW_QA_LESSONS.md](INTERVIEW_QA_LESSONS.md) |
| 비용 | [FREE_MODE.md](FREE_MODE.md) |
| E2E | [DEMO_E2E_RESULT.md](DEMO_E2E_RESULT.md) |
| 노션 가이드 | [NOTION_GUIDE.md](NOTION_GUIDE.md) (본 문서) |
