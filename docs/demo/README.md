# 데모 자료 세트 (포트폴리오용)

채용관·발표용으로 **로컬 UI**와 **EKS E2E 실전 기록**을 한곳에 모았습니다.  
(현재 AWS 인프라는 destroy 상태 — 과금 없음. 재현 시 유료 동의 필요.)

## 스크린샷

| 파일 | 내용 |
|------|------|
| [screenshots/01-local-home.png](screenshots/01-local-home.png) | 로컬 데모 홈 — `/health`, `/api/hello`, `/api/info` |
| [screenshots/02-local-lab.png](screenshots/02-local-lab.png) | lab.html — 무료/유료 안내 · 체크리스트 |
| [screenshots/03-eks-e2e-terminal.png](screenshots/03-eks-e2e-terminal.png) | EKS E2E curl 200 성공 기록 |
| [screenshots/04-architecture-path.jpg](screenshots/04-architecture-path.jpg) | 트래픽 경로 다이어그램 (Internet → ALB → Pods) |
| [screenshots/03-eks-e2e-curl-evidence.txt](screenshots/03-eks-e2e-curl-evidence.txt) | 동일 내용 텍스트 로그 |

### 미리보기

#### 1) 로컬 UI (과금 0)

![로컬 데모 홈](screenshots/01-local-home.png)

![실습 lab 페이지](screenshots/02-local-lab.png)

#### 2) EKS E2E 실전 (과거 성공 · 이후 destroy)

![E2E 터미널 검증](screenshots/03-eks-e2e-terminal.png)

![아키텍처 경로](screenshots/04-architecture-path.jpg)

## 30초 스토리 (발표 스크립트)

1. **문제:** 콘솔 수동 인프라는 재현·비용 통제가 어렵다.  
2. **해결:** Terraform 3-Tier + Bastion/SSM + EKS(ALB Ingress) + GitHub Actions.  
3. **평소:** `./scripts/dev-free.sh` — 로컬 Docker만 (과금 0).  
4. **데모 날:** 유료 동의 후 apply → ALB로 FE/BE 200 → **즉시 destroy**.  
5. **안전:** `acknowledge_paid_aws` + `YES_I_ACCEPT_AWS_CHARGES` 이중 확인.

## 재현 명령

```bash
# 로컬 (지금 바로)
./scripts/dev-free.sh
# open http://localhost:8080
# open http://localhost:8080/lab.html

# EKS E2E (유료 — 사용자 동의 후)
# docs/EKS_E2E_CHECKLIST.md
# ./scripts/terraform-apply-paid.sh
# … 데모 후
# ./scripts/terraform-destroy-paid.sh
```

## 관련 문서

- [DEMO_E2E_RESULT.md](../DEMO_E2E_RESULT.md) — E2E 결과 요약  
- [FREE_MODE.md](../FREE_MODE.md) — 무료 개발  
- [EKS_E2E_CHECKLIST.md](../EKS_E2E_CHECKLIST.md) — 전체 명령  
