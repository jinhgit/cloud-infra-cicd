# 면접 Q&A · Lessons Learned

**프로젝트:** IaC 3-Tier + Bastion + EKS(ALB Ingress) + GitHub Actions  
**저장소:** https://github.com/jinhgit/cloud-infra-cicd  
**포지션 가정:** 클라우드 엔지니어 / DevOps / 플랫폼 주니어  

---

## 1. 30초·2분 소개 (외우기)

### 30초

> Terraform으로 서울 리전 2-AZ 3-Tier VPC를 코드화했고, Bastion(SSH/SSM)과 EKS Private 노드 위에 FE/BE를 올려 ALB Ingress로 외부에 서비스하는 경로를 검증했습니다. 평소는 Docker Compose로 과금 없이 개발하고, AWS 유료 리소스는 이중 확인 후에만 켰다가 destroy 합니다. CI는 fmt/validate/plan과 테스트·이미지 빌드를 GitHub Actions로 돌립니다.

### 2분 (구조)

1. **문제:** 콘솔 수동 구축 → 재현·리뷰·비용 통제 어려움  
2. **네트워크:** Public / Private Web / Private DB, NAT AZ별, SG 최소 권한  
3. **워크로드:** EKS + AWS LB Controller + Ingress → ALB  
4. **앱:** Nginx FE + Node BE, same-origin `/health` `/api`  
5. **운영:** Bastion, 무료 모드 기본, CI, destroy 습관  
6. **트러블슈팅:** EKS 버전, Free Tier 인스턴스, arm64 이미지, Controller IAM  

---

## 2. 면접 Q&A

### Q1. 왜 3-Tier / Public·Private 분리를 했나요?

**A.** 인터넷 접점은 Public(ALB, Bastion, NAT)에만 두고, 앱·DB는 Private에 두어 공격 면을 줄였습니다. DB 서브넷은 인터넷 라우트를 두지 않아 격리합니다. 최소 권한 SG로 ALB→앱, 앱→DB, Bastion→SSH(내 IP)만 허용합니다.

### Q2. NAT를 AZ마다 둔 이유는? 비용은?

**A.** AZ 장애 시 교차 AZ 의존을 줄이고, 동일 AZ 아웃바운드 패턴을 학습하기 위함입니다. NAT는 시간 과금이 커서 기본 `nat_gateway_count=0` 이고, 데모 시에만 `acknowledge_paid_aws` 동의 후 켭니다. 끝나면 destroy 합니다.

### Q3. 왜 워커를 Private에 두나요?

**A.** 노드에 공인 IP를 주지 않고, 이미지 pull·업데이트는 NAT 아웃바운드로 처리합니다. 인바운드 사용자 트래픽은 ALB→Pod 경로만 엽니다.

### Q4. ALB Ingress를 쓴 이유는? NLB와 차이는?

**A.** HTTP 경로 기반 라우팅(`/` FE, `/api` BE)과 헬스체크에 ALB+Ingress가 맞습니다. NLB는 L4에 가깝고 경로 분기 스토리가 약합니다. AWS Load Balancer Controller + IRSA로 ALB를 프로비저닝했습니다.

### Q5. IRSA가 뭔가요?

**A.** Pod/Controller ServiceAccount가 IAM Role을 맡는 방식입니다. 노드 인스턴스 롤에 과도한 권한을 몰지 않고, LB Controller 전용 Role + OIDC 조건으로 최소 권한에 가깝게 갑니다.

### Q6. Free Tier 계정에서 겪은 문제는?

**A.** `t3.medium` 노드가 Free Tier 비적격으로 ASG 기동이 실패했습니다. `t3.small`로 바꿔 해결했습니다. 또한 EKS 1.29가 리전에서 unsupported라 1.32로 올렸습니다.

### Q7. Mac에서 이미지 pull 실패 원인은?

**A.** Apple Silicon에서 기본 arm64 이미지를 빌드해 x86 노드에서 `no match for platform` 이 났습니다. `docker build --platform linux/amd64` 로 통일했고, CI/스크립트에도 고정했습니다.

### Q8. LB Controller가 ALB를 못 만들 때는?

**A.** IAM 정책이 구버전이면 `DescribeListenerAttributes`, `GetSecurityGroupsForVpc` 등에서 AccessDenied가 납니다. 컨트롤러 버전에 맞는 IAM 정책(v2.13)으로 갱신해 해결했습니다. 서브넷 태그(`kubernetes.io/role/elb`)도 확인합니다.

### Q9. 왜 CI에서 apply를 안 하나요?

**A.** 실수로 NAT/EKS가 떠서 과금·장애가 나는 것을 막기 위해서입니다. CI는 검증(fmt/validate/plan/test/build)에 집중하고, apply는 로컬에서 사용자 이중 확인 후에만 합니다.

### Q10. 비용 가드는 어떻게 설계했나요?

**A.**  
1) `acknowledge_paid_aws` 기본 false  
2) `confirm_paid_apply = "YES_I_ACCEPT_AWS_CHARGES"` 필수  
3) 동의 없으면 NAT/EKS/Bastion count=0  
4) VPC lifecycle precondition  
5) `AGENTS.md` — AI도 승인 없이 유료 apply 금지  
6) `./scripts/dev-free.sh` 일상 경로  

### Q11. Bastion과 SSM을 같이 둔 이유는?

**A.** SSH(키+my_ip)는 전통적 점프 경로, SSM은 키·22 포트 부담을 줄입니다. Public 서브넷 + SSM 인스턴스 프로파일로 Online을 확인했습니다.

### Q12. 라이브 URL이 없는 이유는? 단점 아닌가요?

**A.** 포트폴리오 목적이라 상시 ALB/EKS 비용을 피했습니다. 대신 스크린샷·E2E 로그·로컬 Compose 재현·destroy 검증으로 “동작 증거”를 남겼습니다. 비용 최적화 설계로 설명합니다.

### Q13. 상태 파일(state)은?

**A.** 학습 단계에서는 로컬 state, `.gitignore`로 커밋 금지. 팀/CI apply 시 S3+DynamoDB lock을 다음 단계로 문서화해 두었습니다.

### Q14. CI 인증은 Access Key인가요, OIDC인가요?

**A.** **OIDC로 전환 완료**했습니다. GitHub Secret 은 `AWS_ROLE_ARN` 만 두고 장기 Access Key Secret 은 삭제했습니다. Role trust 는 **main 브랜치**로 좁혔고, plan only(ReadOnly)입니다. 적용 중 `sub` 이 `repo:owner@id/repo@id:ref:...` 형태여 CloudTrail로 확인·trust 를 고친 경험이 있습니다. (`docs/OIDC_SETUP.md`)

### Q14-b. 보안에서 더 하고 싶은 것은?

**A.** 앱 단위 IRSA 확대, 이미지 스캔, NetworkPolicy, remote state 암호화 등을 다음 학습 후보로 둡니다.

### Q15. 장애가 나면 어디부터 보나요?

**A.**  
1) Pod: `kubectl describe/logs` ImagePullBackOff·CrashLoop  
2) Ingress/Controller 로그·이벤트  
3) 서브넷 태그·SG  
4) IAM/IRSA  
5) NAT/라우팅 (Private 아웃바운드)  

---

## 3. Lessons Learned (회고)

### 잘한 것

- **문서와 코드를 같이** 맞춤 (PRD → 구현 → 체크리스트)  
- **비용·보안을 기능으로** 넣음 (가드, FREE 모드)  
- **E2E까지** 한 번 끝까지 (실패 포함 학습)  
- **로컬 재현**과 **클라우드 데모** 분리  

### 어려웠던 것 · 해결

| 이슈 | 원인 | 해결 |
|------|------|------|
| EKS 1.29 생성 실패 | 리전 미지원 | 1.32 |
| 노드 CREATING 고착 | Free Tier + t3.medium | t3.small |
| ImagePullBackOff | arm64 이미지 | linux/amd64 |
| Ingress ALB 실패 | Controller IAM 구버전 | 정책 v2.13 |
| Bastion 볼륨 | AMI 최소 30GiB | volume 30 |
| OIDC AccessDenied | `sub` 에 owner/repo **숫자 ID** | CloudTrail 확인 후 StringLike 병기 → main-only 로 재축소 |

### 다음에 개선할 것 (선택 학습 · 프로젝트 마감 이후)

1. ~~OIDC로 CI Access Key 제거~~ ✅ 완료  
2. Remote state (S3+DynamoDB)  
3. 관측 (로그/메트릭 최소)  
4. 앱 IRSA 예시  
5. terratest 또는 terraform test  

### 개인적 인사이트

- “돌아가는 데모”보다 **끄는 습관**이 클라우드 신뢰를 만든다.  
- 플랫폼 불일치·IAM·쿼터/Free Tier는 **문서화할수록 포트폴리오 자산**이 된다.  
- 주니어에게 중요한 건 도구 나열이 아니라 **왜 그 아키텍처인지 설명**이다.

---

## 4. 예상 꼬리 질문 치트

| 질문 | 한 줄 |
|------|--------|
| Multi-AZ RDS? | DB 서브넷은 준비, 인스턴스는 비용 때문에 선택 |
| Helm vs raw yaml? | 학습·가시성 위해 raw + Controller만 Helm |
| GitOps? | 다음 단계, 현재는 Actions 빌드 + 수동/스크립트 배포 |
| 왜 2 노드? | Ready≥2 HA 최소, Free Tier 고려 |

---

## 5. 노션용 짧은 카드

**제목:** 면접 핵심 3가지  
1. Private 워크로드 + ALB Ingress  
2. 비용 이중 확인 + destroy  
3. 실전 트러블슈팅 4건  

**링크:** 이 파일 + `docs/demo/README.md` + GitHub  
