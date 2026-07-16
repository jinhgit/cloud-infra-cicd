# [PRD] IaC 기반 클라우드 네트워크 자동화, EKS 워크로드 및 CI/CD 파이프라인

| 항목 | 내용 |
|------|------|
| 문서 버전 | **v1.1** |
| 작성일 | 2026-07-16 |
| 상태 | Approved Draft (학습·구현 기준 문서) |
| 관련 문서 | [기능 명세서](FUNCTIONAL_SPEC.md), [architecture.md](architecture.md), [STAGE_1_DEV_GUIDE.md](STAGE_1_DEV_GUIDE.md) |

---

## 1. 프로젝트 개요

### 1.1 한 줄 요약

**Terraform으로 3-Tier 보안 네트워크를 코드화하고, 동일 VPC 위에 Amazon EKS로 컨테이너 워크로드를 올려 ALB Ingress로 서비스하며, GitHub Actions로 인프라·앱 배포를 자동화하는 포트폴리오형 클라우드 엔지니어링 프로젝트.**

### 1.2 배경

수동 콘솔 작업은 재현성이 낮고 인적 오류·비용 통제가 어렵다. 클라우드 엔지니어 역량을 증명하려면 **네트워크 설계 + IaC + 컨테이너 오케스트레이션(EKS) + CI/CD**를 하나의 스토리로 연결한 결과물이 필요하다.

### 1.3 프로젝트명

코드로 관리하는 보안 네트워크 인프라, EKS 기반 가용성 높은 웹 애플리케이션 및 자동 배포 파이프라인 구축

### 1.4 기간·환경

| 항목 | 값 |
|------|-----|
| 개발 기간 | 계절학기 약 3~4주 (EKS는 **4단계 또는 2단계 후반 확장**으로 배치) |
| 클라우드 | AWS (리전: `ap-northeast-2`) |
| 환경 | 기본 `dev` (필요 시 staging/prod 확장) |
| 저장소 | GitHub |

### 1.5 목표 (Goals)

| ID | 목표 | 성공 기준 |
|----|------|-----------|
| G-1 | 네트워크 아키텍처 설계 능력 증명 | 2-AZ 3-Tier VPC가 Terraform으로 재현 가능 |
| G-2 | IaC로 인프라 가시성·변경 관리 자동화 | `plan`으로 변경 미리보기, `apply`/`destroy`로 수명주기 관리 |
| G-3 | CI/CD로 배포·운영 자동화 경험 | Push/PR 시 validate·plan, 앱/클러스터 배포 경로 확보 |
| G-4 | 보안 표준 준수 | Public/Private 분리, Bastion, NAT, 최소 권한 SG, (EKS) 프라이빗 노드 |
| G-5 | 테스트 비용 통제 | 미사용 시 `terraform destroy`로 잔여 과금 최소화 (EKS 컨트롤 플레인 포함) |
| **G-6** | **EKS로 컨테이너 워크로드 운영** | **동일 VPC에서 클러스터 기동, ALB Ingress → Pod 트래픽 E2E** |

### 1.6 비목표 (Out of Scope)

다음 항목은 본 프로젝트 **범위 밖**이다.

- 멀티 리전 / 멀티 계정 Landing Zone
- **고급 Kubernetes 플랫폼 전체** (Service Mesh, 멀티 클러스터, GitOps 풀스택 등) — 아래 [§14 EKS 확장](#14-eks--kubernetes-확장-권장-a) 비범위 참고
- 상용 관측 스택 전체 구축 (Datadog, 대규모 Prometheus/Grafana 운영 등)
- 프로덕션급 WAF·Shield·고급 위협 탐지
- 복잡한 마이크로서비스·DB 스키마 설계 (DB는 **배치 공간 + 접속 경로** 중심, RDS 실물은 선택)
- 상용 도메인·정식 ACM 인증서 상시 운영 (HTTPS/ACM은 **선택 P1~P2**)
- **k3s / self-managed 전면 대체** (본 PRD의 K8s 경로는 **Amazon EKS 고정**)

> v1.0에서 “Kubernetes / EKS 전체 제외”였던 항목은 **v1.1에서 철회**하고, **최소 EKS 워크로드 경로(권장 A)** 를 범위에 포함한다.

---

## 2. 핵심 가치

| 가치 | 설명 | 구현 방향 |
|------|------|-----------|
| 생산성 | 콘솔 클릭 100% 코드화 | Terraform 파일 분리, 반복 가능한 배포 |
| 보안 | 3-Tier + 최소 권한 | 서브넷 분리, Bastion, SG, EKS 노드 Private 배치 |
| 비용 | 생성·삭제 자유 | destroy 가능, NAT·**EKS 컨트롤 플레인**·노드 과금 인지 |
| 재현성 | 동일 인프라 재생성 | 변수·문서·CI validate/plan |
| 현대화 | 컨테이너 기반 배포 | **EKS + 컨테이너 이미지 + Ingress** |

---

## 3. 사용자·이해관계자

| 역할 | 니즈 |
|------|------|
| 개발자(본인) | 로컬/CI에서 plan·apply, Bastion/`kubectl`로 운영 접근 |
| 리뷰어/채용 담당 | README·다이어그램으로 네트워크→EKS→CI/CD 스토리 파악 |
| 운영(가상) | 배포 자동화, plan/Actions 로그로 원인 파악 |

---

## 4. 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| Cloud | AWS | 서울 리전 |
| IaC | Terraform ≥ 1.5 | AWS Provider |
| **컨테이너 오케스트레이션** | **Amazon EKS** | **권장 A — 학습·포트폴리오 표준** |
| 컨테이너 이미지 저장 | Amazon ECR | CI 빌드 푸시 |
| 클러스터 접근 | `kubectl`, (권장) AWS CLI `eks update-kubeconfig` | Bastion 또는 CI OIDC |
| Ingress / L7 | **AWS Load Balancer Controller** + ALB | Public ALB → Pod |
| CI/CD | GitHub Actions | 인프라 + 이미지 빌드 + 클러스터 배포 |
| 설정 자동화 | User Data / 매니페스트 | Bastion·부트스트랩; 앱은 K8s 매니페스트/Helm(선택) |
| OS (노드) | EKS 최적화 AMI (Amazon Linux 등) | 관리형 노드 그룹 |
| 웹 앱 | 컨테이너화된 간단 앱 (Nginx static / Node.js / 간단 API 중 1) | 포트폴리오용 |
| VCS | GitHub | Secrets / **OIDC 권장** |

**워크로드 기본 경로 (v1.1):**

```
Internet → ALB (Public) → Ingress (AWS LB Controller) → Service → Pod
                              ↑
              Private 서브넷 EKS 워커 노드 (기존 Private Web 활용)
                              ↑
                    VPC / NAT / SG (Stage 1 재사용)
```

---

## 5. 아키텍처 요구사항 요약

상세 다이어그램·CIDR·트래픽 흐름은 [architecture.md](architecture.md)를 따른다. EKS 상세는 [§14](#14-eks--kubernetes-확장-권장-a).

### 5.1 네트워크 (Stage 1 — 변경 없음, EKS 기반)

- VPC: `10.0.0.0/16`
- AZ: `ap-northeast-2a`, `ap-northeast-2c`
- Public 서브넷 2: IGW, Bastion, **ALB(Ingress가 생성·연동)**, NAT
- Private Web 서브넷 2: **EKS 워커 노드 배치 기본 위치** (인바운드 직접 차단, NAT 아웃바운드)
- Private DB 서브넷 2: RDS/DB 배치 공간, 인터넷 경로 없음
- 라우팅: Public → IGW, Private Web → **동일 AZ NAT**, Private DB → 로컬만
- 보안 그룹: ALB / (노드·파드 통신) / Bastion / RDS — EKS 단계에서 규칙 확장

### 5.2 컴퓨팅·로드밸런싱

| 경로 | 용도 | 우선순위 |
|------|------|----------|
| **Primary (EKS)** | 관리형 노드 그룹 + Deployment/Service/Ingress + ALB | **P0 (G-6)** |
| Secondary (선택) | Bastion (운영 점프) | P0 (운영 접근) |
| Legacy/학습 (선택) | Private Web EC2 + Nginx — EKS 이전 **학습용 중간 단계** | **P2** (시간 있을 때만) |

> v1.1 정책: **최종 사용자 트래픽의 목표 경로는 EKS Ingress** 이다.  
> EC2 웹 서버 풀스택은 **필수가 아니며**, 일정 압박 시 **생략 가능**하다.

### 5.3 설계 권장안 (네트워크)

| 항목 | 권장 | 이유 |
|------|------|------|
| NAT Gateway | **AZ당 1개 (총 2개)** | 노드 이미지 pull·아웃바운드 HA. 비용 주의 → destroy |
| Private RT | **AZ별 분리** | 동일 AZ NAT |
| DB SG 포트 | **3306 필수**, 5432 선택 | |
| 서브넷 | **6개** | Public 2 + Web 2 + DB 2 |
| State | 로컬 → **S3 + DynamoDB lock 권장** | CI·동시 apply 방지 |

---

## 6. 단계별 로드맵

### 6.1 [1단계] Terraform 네트워크 IaC (1~2주) — **P0 / Must**

- VPC, IGW, 서브넷 6, NAT×2(+EIP), RT×5, 보안 그룹 베이스
- `validate` / `plan` / `apply` / `destroy`
- **EKS가 재사용할 VPC·서브넷·NAT 완성**이 목표

### 6.2 [2단계] 운영 접근 + (선택) 레거시 웹 — **P0 일부 / P2 일부**

| 항목 | 우선순위 | 설명 |
|------|----------|------|
| Bastion Host | **P0** | SSH / 클러스터 운영 점프 (또는 SSM 병행 선택) |
| 레거시 Web EC2 + ALB TG | **P2** | EKS 전 학습용. 생략 시 2단계를 Bastion 중심으로 축소 |
| RDS 실물 | **P2** | 서브넷·SG만으로도 1단계 충족 |

### 6.3 [3단계] GitHub Actions — 인프라 CI — **P0**

1. Lint/Validate: `terraform fmt -check`, `validate`
2. Plan: PR/push 시 `terraform plan`
3. Apply: `main` 보호 규칙 하 apply (수동 승인 권장)
4. 인증: Secrets 최소, **OIDC + IAM Role 권장**

### 6.4 [4단계] EKS 워크로드 + 앱 CD — **P0 (G-6) / P1 (자동 배포)**

1. Terraform으로 EKS 클러스터 + 관리형 노드 그룹 (Private Web 서브넷)
2. AWS Load Balancer Controller 설치 (IRSA)
3. 샘플 앱: Deployment + Service + Ingress → **Public ALB**
4. ECR 리포지토리 + 이미지 빌드
5. Actions: 이미지 푸시 → `kubectl apply` (또는 Helm) 배포
6. (선택) 앱 → RDS 연결 검증

### 6.5 우선순위 정의

| 등급 | 의미 |
|------|------|
| P0 / Must | 없으면 프로젝트 목표 미달성 |
| P1 / Should | 포트폴리오 완성도에 중요 |
| P2 / Could | 여유 시 |

---

## 7. 기능 요구사항 (PRD 수준)

세부 ID·수락 기준은 [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md)에 정의·확장한다.

| Epic | 요약 | 단계 | 우선순위 |
|------|------|------|----------|
| E1 Network IaC | 3-Tier 네트워크 Terraform | 1 | P0 |
| E2 Security Baseline | SG·Bastion IP·시크릿 비커밋 | 1~4 | P0 |
| E3 Compute & Access | Bastion (+ 선택 EC2 웹) | 2 | P0 / P2 |
| E4 Bootstrap | (선택) EC2 Nginx | 2 | P2 |
| **E9 EKS Cluster** | **클러스터·노드·IAM/OIDC** | **4** | **P0** |
| **E10 EKS Ingress & App** | **LB Controller, 샘플 앱, ALB** | **4** | **P0** |
| E5 CI/CD Infra | fmt/validate/plan/apply | 3 | P0 |
| **E11 CI/CD Container** | **ECR 빌드·푸시, 클러스터 배포** | **4** | **P1** |
| E7 Remote State | S3 + DynamoDB | 1 후반~3 | P1 |
| E8 Docs | README·다이어그램·destroy 절차 | 전 구간 | P0 |

---

## 8. 비기능 요구사항 (NFR)

| ID | 영역 | 요구 |
|----|------|------|
| NFR-1 | 보안 | 키 하드코딩 금지. tfvars/state 미커밋. CI는 Secrets 또는 **OIDC** |
| NFR-2 | 비용 | destroy로 정리. **NAT + EKS 컨트롤 플레인 + 노드 + ALB + EIP** 상시 과금 인지 |
| NFR-3 | 가용성 | 2 AZ 노드 분산, ALB 다중 타깃(Pod) |
| NFR-4 | 재현성 | Terraform + 매니페스트로 재배포 가능 |
| NFR-5 | 관측(최소) | ALB/Ingress Health, `kubectl get pods`로 Ready 확인 |
| NFR-6 | 문서화 | README에 네트워크 + **EKS 트래픽 경로** + destroy 순서 |
| NFR-7 | 변경 안전 | plan 없는 apply 지양. main apply·클러스터 변경은 보호/승인 권장 |
| **NFR-8** | **EKS 보안** | 노드 **Private**, API 엔드포인트는 **Private 권장(또는 Public+제한)**, IRSA 사용, 불필요 `0.0.0.0/0` SSH 금지 |
| **NFR-9** | **Destroy 순서** | 앱/Ingress(ALB) 삭제 → 애드온 → 노드/클러스터 → 네트워크. **고아 ALB·SG 잔존 점검** |

---

## 9. 성공 지표 (Definition of Done — 프로젝트 전체)

### 네트워크·보안 (Stage 1+)

- [ ] `terraform apply`로 Stage 1 네트워크 생성, `output`으로 주요 ID 확인
- [ ] SG·라우팅이 PRD 최소 권한·HA NAT 기준을 만족
- [ ] Bastion은 `my_ip`에서만 SSH 가능 (구현 시)

### EKS (Stage 4) — **G-6**

- [ ] EKS 클러스터 `ACTIVE`, 노드 **Ready ≥ 2** (가능하면 AZ 분산)
- [ ] 샘플 앱 Pod Running
- [ ] **인터넷 → ALB DNS → Ingress → Pod** 로 HTTP 200(또는 의도 응답)
- [ ] 워커 노드에 공인 SSH 불필요 / 노드 서브넷이 Private
- [ ] (P1) Actions로 이미지 빌드·배포 1회 이상 성공
- [ ] (P0 운영) `terraform destroy` 또는 문서화된 삭제 순서로 **EKS·ALB 잔여 과금 제거** 가능

### CI/CD·문서

- [ ] PR에서 Terraform fmt/validate/plan 통과
- [ ] README에 아키텍처(네트워크+EKS)·배포·destroy 절차
- [ ] 저장소에 시크릿·tfvars·state 미포함

---

## 10. 리스크 및 완화

| 리스크 | 영향 | 완화 |
|--------|------|------|
| NAT/ALB/EKS 비용 | 예상 외 과금 | 작업 후 destroy, 짧은 데모 창, 예산 알람(선택) |
| EKS 컨트롤 플레인 상시 과금 | 방치 시 누적 | 체크리스트에 “클러스터 삭제” 필수화 |
| Ingress ALB 고아 리소스 | destroy 후에도 과금 | NFR-9 순서, AWS 콘솔에서 ALB/SG 점검 |
| IAM/IRSA 설정 오류 | Controller·배포 실패 | 공식 모듈/문서 패턴, 최소 권한 롤 |
| 범위 과다 | 미완성 | **레거시 EC2 웹 P2**, Mesh/GitOps 제외, 샘플 앱 1개 |
| 키 유출 | 보안 사고 | .gitignore, OIDC, 로테이션 |
| 쿼터/AZ | apply 실패 | 사전 한도 확인 |

---

## 11. 마일스톤 일정 (권장, EKS 포함)

| 주차 | 산출물 |
|------|--------|
| 1주 | Stage 1 네트워크 완성 (NAT 2·RT 5), plan/apply 검증 |
| 2주 | Bastion + (선택 P2) 레거시 웹 **또는** EKS Terraform 착수 |
| 3주 | EKS 클러스터·노드·LB Controller·샘플 Ingress E2E |
| 4주 | Actions (infra plan + ECR/deploy), README·destroy 리허설, 데모 |

일정이 빠듯하면 **2주 레거시 EC2를 건너뛰고 EKS로 직행**하는 것이 v1.1 권장이다.

---

## 12. 문서 체계

```
docs/
├── PRD.md                 # 본 문서 — 왜 / 무엇을 / EKS 확장 / 성공 기준
├── FUNCTIONAL_SPEC.md     # 기능 단위·수락 기준 (EKS Feature ID 포함)
├── architecture.md        # 네트워크 상세 (EKS 다이어그램은 추후 보강)
├── PROJECT_STRUCTURE.md   # 파일 역할
└── STAGE_*_DEV_GUIDE.md   # 단계별 구현 가이드
```

---

## 13. 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | 2026-07-16 | 초안 PRD + 문서 통합, NAT/RT 권장안 고정 |
| **v1.1** | **2026-07-16** | **권장 A(EKS) 채택: G-6, §14 EKS 확장, 로드맵 4단계, Out of Scope 조정** |

---

## 14. EKS / Kubernetes 확장 (권장 A)

본 절은 v1.1에서 추가된 **제품 범위 정의**이다. 구현 시 이 절을 우선한다.

### 14.1 목표 아키텍처 (고정)

```
┌─────────────────────────────────────────────────────────────┐
│ VPC 10.0.0.0/16  (Stage 1 Terraform)                        │
│                                                             │
│  Public AZ-A/C          Private Web AZ-A/C     Private DB   │
│  ┌──────────────┐       ┌──────────────────┐   ┌─────────┐ │
│  │ IGW, NAT×2   │       │ EKS Worker Nodes │   │ (RDS)   │ │
│  │ Bastion      │       │  Pod / Service   │   │ 공간    │ │
│  │ ALB ◄────────┼───────┤  (Ingress 타깃)  │   └─────────┘ │
│  └──────▲───────┘       └────────▲─────────┘               │
│         │                        │                          │
│         │         EKS Control Plane (AWS 관리형)            │
│         │              IRSA / OIDC                          │
└─────────┼────────────────────────┼──────────────────────────┘
          │                        │
     Internet 사용자          ECR / 외부 API (via NAT)
```

**트래픽 (필수 데모 경로)**

```
Internet → ALB (Public) → AWS Load Balancer Controller(Ingress)
         → Service (ClusterIP) → Pod (Private 노드)
```

**운영 경로**

```
개발자 → Bastion(또는 SSM/CI) → kubectl → EKS API
```

### 14.2 In Scope (범위 안) — Must / Should

#### P0 — Must (G-6 달성 최소선)

| ID | 항목 | 설명 |
|----|------|------|
| EKS-IN-01 | EKS 클러스터 | Terraform으로 생성, 리전 `ap-northeast-2` |
| EKS-IN-02 | 관리형 노드 그룹 | **최소 2노드**, Private Web 서브넷, 가능하면 **AZ 분산** |
| EKS-IN-03 | 기존 VPC 재사용 | Stage 1 VPC/서브넷/NAT **신규 VPC 금지(기본)** |
| EKS-IN-04 | 클러스터 접근 | `aws eks update-kubeconfig` 후 `kubectl get nodes` Ready |
| EKS-IN-05 | AWS Load Balancer Controller | Ingress → **ALB** 생성·연동 (IRSA) |
| EKS-IN-06 | 샘플 워크로드 | Deployment + Service + Ingress **1세트** |
| EKS-IN-07 | E2E HTTP | 인터넷에서 ALB 주소로 앱 응답 확인 |
| EKS-IN-08 | 비용 회수 | 문서화된 순서로 클러스터·ALB·노드 삭제 가능 |

#### P1 — Should (포트폴리오 완성도)

| ID | 항목 | 설명 |
|----|------|------|
| EKS-IN-09 | Amazon ECR | 앱 이미지 저장소 Terraform 또는 콘솔+문서 |
| EKS-IN-10 | CI 이미지 파이프라인 | Actions: build → push ECR |
| EKS-IN-11 | CD 배포 | Actions: 매니페스트/`kubectl` 또는 Helm으로 클러스터 반영 |
| EKS-IN-12 | Health | Ingress/ALB 헬스체크 경로 (`/` 또는 `/health`) |
| EKS-IN-13 | 리소스 요청 | Pod `requests`/`limits` 최소 설정 |
| EKS-IN-14 | 태그·이름 | 클러스터·노드에 project/environment 태그 |

#### P2 — Could (여유 시)

| ID | 항목 | 설명 |
|----|------|------|
| EKS-IN-15 | Helm 차트 | 샘플 앱 Helm 패키징 |
| EKS-IN-16 | HTTPS | ACM + Ingress TLS |
| EKS-IN-17 | HPA | CPU 기반 오토스케일 데모 |
| EKS-IN-18 | 앱→RDS | Private DB 연결 (시크릿은 K8s Secret/외부 SM 중 단순 경로) |
| EKS-IN-19 | 클러스터 로그 | CloudWatch 로그 그룹 최소 연동 |
| EKS-IN-20 | Karpenter / Fargate | 고급 스케줄링 — **기본 경로 아님** |

### 14.3 Out of Scope (범위 밖) — EKS 한정

다음을 **구현 성공 조건에 넣지 않는다.**

| 제외 항목 | 이유 |
|-----------|------|
| Istio / Linkerd 등 Service Mesh | 일정·복잡도 |
| Argo CD / Flux 풀 GitOps | Actions 직접 배포로 충분 (P1) |
| 멀티 클러스터·멀티 리전 EKS | 범위 과다 |
| 프로덕션급 NetworkPolicy 전체 설계 | 최소 데모 후 선택 |
| 자체 구축 etcd / kops / k3s 전면 대체 | **EKS 고정** |
| 대규모 마이크로서비스 (서비스 5개+) | 샘플 **1 앱** |
| 상용 모니터링 SaaS 필수화 | 선택 |
| Windows 노드, GPU 노드 | 불필요 |
| 블루/그린·카나리 고급 트래픽 전환 | 기본 RollingUpdate면 충분 |

### 14.4 설계 결정 (권장 기본값)

| 항목 | 권장 기본값 | 비고 |
|------|-------------|------|
| 클러스터 버전 | 지원 LTS에 가까운 EKS 버전 (구현 시점 최신 -1 정도) | 문서에 버전 고정 |
| 노드 | Managed Node Group, 인스턴스 **t3.small 또는 t3.medium** | 비용·실습 균형 |
| 노드 수 | **desired=2**, min=2, max=3~4 | 2 AZ |
| 서브넷 | **Private Web**에 노드 | Public 노드 금지(기본) |
| 클러스터 엔드포인트 | **Public + Private** 또는 **Private only** | Private only 시 Bastion/CI 경로 필수 |
| 네트워크 플러그인 | AWS VPC CNI (기본) | |
| 앱 노출 | **Ingress + ALB** (NLB-only 아님) | 권장 A 다이어그램과 일치 |
| 네임스페이스 | `default` 또는 `app` 단일 | 단순화 |
| IaC 경계 | 클러스터·노드·IRSA·ECR = **Terraform** / 앱 매니페스트 = **YAML(또는 Helm)** | |
| 기존 SG | Stage 1 SG 확장 또는 EKS 모듈 생성 SG와 연동 | 문서에 매핑 표 유지 |

### 14.5 레거시 EC2 웹과의 관계

| 정책 | 내용 |
|------|------|
| 최종 목표 경로 | **EKS Ingress only** |
| EC2 Nginx 웹 | **P2 학습 옵션**. 구현 시 README에 “레거시 경로”로 명시 |
| 동시 운영 | 비권장(비용·복잡도). 데모는 **EKS 경로 1개**에 집중 |
| Stage 1 SG `web_ec2` | EKS 전환 후에도 남겨 두거나, 노드/파드용 SG로 역할 재정의 — 구현 시 명세 갱신 |

### 14.6 성공 기준 (EKS 전용 Acceptance — 데모 체크리스트)

데모 당일 아래를 **순서대로** 통과하면 G-6 달성으로 본다.

1. **클러스터**
   - [ ] `aws eks describe-cluster` → status `ACTIVE`
   - [ ] `kubectl get nodes` → Ready 노드 ≥ 2
2. **워크로드**
   - [ ] `kubectl get deploy,po,svc,ing -A` (또는 app ns) → Pod Running, Ingress ADDRESS(ALB) 존재
3. **외부 트래픽**
   - [ ] `curl -sS -o /dev/null -w "%{http_code}\n" http://<ALB-DNS>/` → **200** (또는 앱이 정한 코드)
4. **네트워크 격리 의도**
   - [ ] 노드가 Private 서브넷에 있음 (콘솔 또는 `describe-instances`)
   - [ ] 인터넷에서 노드 Private IP로 직접 HTTP 불가
5. **자동화 (P1)**
   - [ ] Actions 로그에 ECR push 및 배포 job 성공 기록 1회 이상
6. **비용 통제**
   - [ ] destroy/삭제 런북대로 클러스터 제거 후 EKS·관련 ALB 과금 요소 잔존 없음(콘솔 확인)

### 14.7 실패로 보지 않는 것 (명시)

- HTTPS/커스텀 도메인 미적용
- HPA·Mesh·GitOps 미적용
- RDS 미연결 (앱이 정적/헬스만 응답해도 OK)
- 레거시 EC2 웹 미구축

### 14.8 비용·운영 주의 (필수 고지)

| 리소스 | 주의 |
|--------|------|
| EKS 컨트롤 플레인 | **클러스터 존재 시간 동안 과금** (노드 0이어도 발생) |
| Managed Nodes | EC2 요금 |
| NAT×2 | 기존 Stage 1과 동일·가중 |
| ALB | Ingress 생성 시 추가 과금 가능 |
| ECR | 소량 스토리지는 낮음 |

**운영 규칙:** 실습·데모 종료 후 **당일 destroy**를 기본으로 한다.

### 14.9 구현 산출물 (예상 디렉터리 — 가이드)

```
terraform/
  ... (기존 Stage 1)
  eks.tf / iam_eks.tf / ecr.tf   # 예시 파일명 — 구현 시 PROJECT_STRUCTURE 갱신

k8s/   또는  manifests/
  namespace.yaml
  deployment.yaml
  service.yaml
  ingress.yaml

.github/workflows/
  terraform.yml          # Stage 3
  deploy-app.yml         # Stage 4 CD (P1)
```

### 14.10 기능 명세 추적

| PRD 항목 | 기능 명세 (예정/확장) |
|----------|------------------------|
| EKS-IN-01~08 | F-EKS-01 ~ F-EKS-08 (P0) |
| EKS-IN-09~14 | F-EKS-09 ~ (P1) |
| EKS-IN-15~20 | F-EKS-xx (P2) |

상세 AC는 [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) EKS 섹션을 따른다.

---

## 15. 의사결정 로그 (ADR 요약)

| 날짜 | 결정 | 선택 | 대안 기각 이유 |
|------|------|------|----------------|
| 2026-07-16 | 컨테이너 플랫폼 | **Amazon EKS (권장 A)** | k3s는 비용엔 유리하나 포트폴리오 표준성 낮음 |
| 2026-07-16 | 트래픽 진입 | **ALB + AWS LB Controller Ingress** | NLB-only는 L7·헬스 스토리 약함 |
| 2026-07-16 | 노드 배치 | **Private Web 서브넷** | Public 노드는 보안 모델과 불일치 |
| 2026-07-16 | 레거시 EC2 웹 | **P2 선택** | EKS와 이중 유지 시 일정·비용 리스크 |
| 2026-07-16 | 앱 CD | **Actions + ECR + kubectl (P1)** | 초기 Argo CD는 범위 과다 |
