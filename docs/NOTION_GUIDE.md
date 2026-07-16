# 노션 정리 가이드

이 저장소 문서를 **노션 포트폴리오 페이지**로 옮길 때 쓰는 템플릿입니다.  
아래 블록을 노션에 복사한 뒤, 링크만 GitHub raw/blob URL로 바꾸면 됩니다.

---

## 1. 권장 노션 구조 (페이지 트리)

```text
📁 포트폴리오
└── 📄 Cloud Infra CI/CD (대표 프로젝트)
    ├── 📄 01. 한 줄 소개 · 성과 (← RESUME_ONE_PAGER)
    ├── 📄 02. 아키텍처 · 데모 스크린샷 (← demo/)
    ├── 📄 03. 기술 스택 · 링크
    ├── 📄 04. 면접 Q&A · Lessons (← INTERVIEW_QA_LESSONS)
    ├── 📄 05. 비용·무료 모드 (← FREE_MODE 요약)
    ├── 📄 06. OIDC 설정 체크리스트 (← OIDC_SETUP 요약)
    └── 📄 07. 회고 · Next
```

---

## 2. 표지 페이지 (복붙용)

### 제목
`[Project] IaC 3-Tier + EKS + GitHub Actions`

### 한 줄
Terraform으로 AWS 네트워크·Bastion·EKS(ALB Ingress)를 코드화하고, 평소는 Docker로 무과금 개발·유료 클라우드는 이중 확인 후 짧은 데모·destroy.

### 배지/링크
- GitHub: https://github.com/jinhgit/cloud-infra-cicd  
- 데모 세트: `docs/demo/README.md`  
- 원페이지: `docs/RESUME_ONE_PAGER.md`  

### 커버용 이미지 (노션에 업로드)
1. `docs/demo/screenshots/04-architecture-path.jpg`  
2. `docs/demo/screenshots/01-local-home.png`  
3. `docs/demo/screenshots/03-eks-e2e-terminal.png`  

---

## 3. 노션 데이터베이스 (선택) — “프로젝트 카드”

| 속성 | 타입 | 예시 값 |
|------|------|---------|
| Name | Title | Cloud Infra CI/CD |
| Role | Select | Cloud / DevOps |
| Stack | Multi-select | AWS, Terraform, EKS, Actions |
| Status | Select | Portfolio-ready |
| Cost | Select | Free-by-default |
| GitHub | URL | (저장소) |
| Highlight | Text | E2E ALB 200 + 비용 가드 |

---

## 4. 페이지별 채울 내용 (체크)

### 01. 한 줄 소개 · 성과
- [ ] `RESUME_ONE_PAGER.md` 의 **핵심 성과 불릿** 붙여넣기  
- [ ] 이력서 문장 1개  
- [ ] 면접 강조 3가지  

### 02. 아키텍처 · 데모
- [ ] 스크린샷 4장 갤러리  
- [ ] 30초 발표 스크립트 (`docs/demo/README.md`)  
- [ ] “라이브 URL 없음 = 비용 설계” 한 줄  

### 03. 기술 스택 · 링크
- [ ] 키워드 나열  
- [ ] GitHub Actions 배지 설명 (초록 = CI 통과)  

### 04. 면접 Q&A
- [ ] `INTERVIEW_QA_LESSONS.md` 에서 Q1~Q5 우선 암기  
- [ ] Lessons 표 (이슈 4건)  

### 05. 비용
- [ ] 무료: `dev-free.sh`  
- [ ] 유료: 이중 확인 문구  
- [ ] destroy 습관  

### 06. OIDC
- [ ] `OIDC_SETUP.md` 체크리스트 표만 옮기기  
- [ ] 계정 `447170313588` / repo `jinhgit/cloud-infra-cicd`  
- [ ] 적용 여부: 미적용 / 적용 완료  

### 07. 회고 · Next
- [ ] 잘한 것 3 / 개선 3  
- [ ] Next: OIDC 적용, remote state, 관측  

---

## 5. 노션 토글 템플릿 (면접 준비)

```text
▶ 30초 소개
  (INTERVIEW_QA_LESSONS §1)

▶ 왜 Private 노드?
  (Q3)

▶ 비용 어떻게 막았나?
  (Q10)

▶ 실패 경험
  (Lessons 표)
```

---

## 6. GitHub → 노션 링크 팁

- 문서: `https://github.com/jinhgit/cloud-infra-cicd/blob/main/docs/파일명.md`  
- 이미지: raw URL  
  `https://raw.githubusercontent.com/jinhgit/cloud-infra-cicd/main/docs/demo/screenshots/01-local-home.png`  
- 노션 이미지 블록에 raw URL 붙이면 README와 동기화 가능  

---

## 7. 이 저장소 신규 문서 맵 (노션 목차용)

| 노션 섹션 | 파일 (신규) |
|-----------|-------------|
| OIDC | [OIDC_SETUP.md](OIDC_SETUP.md) |
| 면접 | [INTERVIEW_QA_LESSONS.md](INTERVIEW_QA_LESSONS.md) |
| 이력서 1p | [RESUME_ONE_PAGER.md](RESUME_ONE_PAGER.md) |
| 노션 가이드 | [NOTION_GUIDE.md](NOTION_GUIDE.md) (본 문서) |
| 로컬 게이트 | 루트 `Makefile` → `make check` |

기존 PRD/architecture/demo 등은 그대로 두고 위 페이지만 추가하면 됩니다.
