# 기능 명세서 (Functional Specification)

| 항목 | 내용 |
|------|------|
| 문서 버전 | **v1.1** |
| 작성일 | 2026-07-16 |
| 상위 문서 | [PRD.md](PRD.md) v1.1 (EKS 권장 A 포함) |
| 대상 시스템 | AWS 3-Tier 네트워크 + **Amazon EKS** + Terraform IaC + GitHub Actions CI/CD |
| 상태 | Draft for Implementation |

---

## 1. 문서 목적

본 문서는 PRD의 목표를 **구현 가능한 기능 단위(Feature)** 로 분해하고, 각 기능의 **입력·동작·출력·수락 기준(Acceptance Criteria)** 을 정의한다.  
개발·검증·데모 시 이 문서의 AC를 체크리스트로 사용한다.

### 1.1 우선순위 표기

| 기호 | 의미 |
|------|------|
| P0 | Must — 미구현 시 단계/프로젝트 실패 |
| P1 | Should — 포트폴리오 완성도에 중요 |
| P2 | Could — 여유 시 |

### 1.2 단계 표기

| 단계 | 범위 |
|------|------|
| S1 | Terraform 네트워크 인프라 |
| S2 | Bastion·(선택) 레거시 EC2 웹 |
| S3 | CI/CD 인프라 (fmt/validate/plan) |
| **S4** | **EKS 클러스터·Ingress 앱·컨테이너 CD** |

---

## 2. 시스템 컨텍스트

**Primary (PRD v1.1 — 권장 A)**

```
[개발자] --SSH(22)--> [Bastion | Public] --kubectl--> [EKS API]
[인터넷 사용자] --HTTP--> [ALB | Public] --> [Ingress] --> [Service] --> [Pod | Private 노드]
[Pod] --outbound--> [NAT] --> [IGW] --> Internet (ECR pull 등)
[GitHub Actions] --OIDC/Secrets--> [AWS API] + [ECR] + [EKS deploy]
```

**Secondary / Legacy (P2 — 선택)**

```
[인터넷] --> [ALB] --> [Web EC2 | Private Web]   # EKS 전 학습용, 최종 목표 경로 아님
```

---

## 3. 기능 목록 요약

| ID | 기능명 | 단계 | 우선순위 |
|----|--------|------|----------|
| F-NET-01 | VPC 및 Internet Gateway 생성 | S1 | P0 |
| F-NET-02 | Public / Private Web / Private DB 서브넷 | S1 | P0 |
| F-NET-03 | NAT Gateway 및 Elastic IP | S1 | P0 |
| F-NET-04 | 라우팅 테이블 및 서브넷 연결 | S1 | P0 |
| F-SEC-01 | ALB 보안 그룹 | S1 | P0 |
| F-SEC-02 | Web EC2 보안 그룹 | S1 | P0 |
| F-SEC-03 | Bastion 보안 그룹 | S1 | P0 |
| F-SEC-04 | RDS/DB 보안 그룹 | S1 | P0 |
| F-IAC-01 | 변수·로컬·출력 구조화 | S1 | P0 |
| F-IAC-02 | 로컬 State 및 destroy 지원 | S1 | P0 |
| F-IAC-03 | Remote State (S3 + DynamoDB) | S1~S3 | P1 |
| F-CMP-01 | Bastion Host EC2 | S2 | P0 |
| F-CMP-02 | Web EC2 (다중 AZ) — **레거시** | S2 | **P2** |
| F-CMP-03 | ALB + TG (레거시 EC2용) | S2 | **P2** |
| F-CMP-04 | Nginx 자동 기동 (레거시) | S2 | **P2** |
| F-CMP-05 | RDS 또는 DB 인스턴스 | S2 | P2 |
| F-CICD-01 | Terraform fmt / validate | S3 | P0 |
| F-CICD-02 | Terraform plan (PR/push) | S3 | P0 |
| F-CICD-03 | Terraform apply (main 보호) | S3 | P1 |
| F-CICD-04 | 레거시 EC2 앱 배포 | S3 | P2 |
| F-CICD-05 | 시크릿·OIDC 인증 | S3 | P0 |
| **F-EKS-01** | EKS 클러스터 (Terraform) | **S4** | **P0** |
| **F-EKS-02** | 관리형 노드 그룹 (Private, ≥2) | **S4** | **P0** |
| **F-EKS-03** | 클러스터 접근 (kubeconfig) | **S4** | **P0** |
| **F-EKS-04** | AWS Load Balancer Controller + IRSA | **S4** | **P0** |
| **F-EKS-05** | 샘플 Deployment + Service + Ingress | **S4** | **P0** |
| **F-EKS-06** | E2E: Internet → ALB → Pod | **S4** | **P0** |
| **F-EKS-07** | EKS 관련 destroy/런북 | **S4** | **P0** |
| **F-EKS-08** | ECR 리포지토리 | **S4** | **P1** |
| **F-EKS-09** | CI: 이미지 빌드·ECR 푸시 | **S4** | **P1** |
| **F-EKS-10** | CD: 클러스터 매니페스트 배포 | **S4** | **P1** |
| F-DOC-01 | README·아키텍처 문서화 | All | P0 |

---

## 4. 상세 기능 명세 — Stage 1 (네트워크 IaC)

### F-NET-01 VPC 및 Internet Gateway

| 항목 | 내용 |
|------|------|
| 목적 | 독립 VPC와 인터넷 경계(IGW) 확보 |
| 우선순위 | P0 / S1 |
| 입력 | `vpc_cidr` (기본 `10.0.0.0/16`), `aws_region`, `project_name`, `environment` |
| 동작 | VPC 생성(DNS hostnames/support 활성), IGW 생성 및 VPC 연결 |
| 출력 | `vpc_id`, IGW 리소스 |
| 관련 파일 | `terraform/vpc.tf`, `variables.tf`, `locals.tf` |

**수락 기준**

1. VPC CIDR이 변수와 일치한다.
2. `enable_dns_support`, `enable_dns_hostnames` 가 true이다.
3. IGW가 해당 VPC에 attach 되어 있다.
4. 리소스 Name 태그가 `name_prefix` 규칙을 따른다.

---

### F-NET-02 서브넷 (6개)

| 항목 | 내용 |
|------|------|
| 목적 | 3-Tier × 2-AZ 분리 |
| 우선순위 | P0 / S1 |
| 입력 | `public_subnet_cidrs`, `private_web_subnet_cidrs`, `private_db_subnet_cidrs`, AZ 목록 |
| 동작 | Public 2, Private Web 2, Private DB 2 생성. Public만 `map_public_ip_on_launch = true` |
| 출력 | 각 서브넷 ID 목록 |
| 권장 CIDR | Public `10.0.1.0/24`, `10.0.2.0/24` / Web `10.0.10.0/24`, `10.0.11.0/24` / DB `10.0.20.0/24`, `10.0.21.0/24` |
| 관련 파일 | `terraform/subnets.tf` |

**수락 기준**

1. 서브넷 총 6개가 생성된다.
2. 각 계층이 AZ-A, AZ-C에 1개씩 배치된다.
3. Public만 공인 IP 자동 할당이 켜져 있다.
4. Private 서브넷은 공인 IP 자동 할당이 꺼져 있다.

---

### F-NET-03 NAT Gateway 및 Elastic IP

| 항목 | 내용 |
|------|------|
| 목적 | Private Web의 아웃바운드 인터넷 (업데이트·패키지) |
| 우선순위 | P0 / S1 |
| 권장 구성 | **AZ당 NAT 1 + EIP 1 (총 2)** — PRD 권장안 |
| 동작 | Public 서브넷에 NAT 배치, EIP 연결, IGW 의존성 명시 |
| 출력 | NAT ID, EIP public IP |
| 관련 파일 | `terraform/nat.tf` |

**수락 기준**

1. EIP가 VPC 도메인으로 생성된다.
2. NAT가 Public 서브넷에 위치한다.
3. Private Web 기본 라우트가 동일 AZ NAT를 가리킨다 (F-NET-04와 연동).
4. README 또는 가이드에 NAT 과금 및 destroy 안내가 있다.

**대안 (비용 절감 모드, P2)**  
NAT 1개 + 모든 Private Web이 해당 NAT로 라우팅. README에 모드 명시.

---

### F-NET-04 라우팅 테이블

| 항목 | 내용 |
|------|------|
| 목적 | 계층별 트래픽 경로 통제 |
| 우선순위 | P0 / S1 |
| 권장 구성 | Public RT 1 + Private Web RT AZ별 + Private DB RT AZ별 |
| 동작 | 아래 라우트 규칙 적용 및 서브넷 association |

| RT 유형 | 대상 | 다음 홉 |
|---------|------|---------|
| Public | `0.0.0.0/0` | IGW |
| Private Web | `0.0.0.0/0` | 동일 AZ NAT |
| Private DB | (기본 인터넷 경로 없음) | local only |

**수락 기준**

1. Public 서브넷 트래픽이 IGW로 나간다.
2. Private Web 아웃바운드가 NAT를 경유한다.
3. Private DB에 `0.0.0.0/0` 인터넷 라우트가 없다.
4. association이 누락된 서브넷이 없다.

---

### F-SEC-01 ~ F-SEC-04 보안 그룹

#### F-SEC-01 ALB SG

| 방향 | 프로토콜 | 포트 | 소스/대상 |
|------|----------|------|-----------|
| In | TCP | 80 | `0.0.0.0/0` |
| In | TCP | 443 | `0.0.0.0/0` |
| Out | All | All | `0.0.0.0/0` |

#### F-SEC-02 Web EC2 SG

| 방향 | 프로토콜 | 포트 | 소스/대상 |
|------|----------|------|-----------|
| In | TCP | 80 | ALB SG |
| In | TCP | 443 | ALB SG (필요 시) |
| Out | All | All | `0.0.0.0/0` |

#### F-SEC-03 Bastion SG

| 방향 | 프로토콜 | 포트 | 소스/대상 |
|------|----------|------|-----------|
| In | TCP | 22 | `var.my_ip` (예: `x.x.x.x/32`) |
| Out | All | All | `0.0.0.0/0` |

#### F-SEC-04 RDS/DB SG

| 방향 | 프로토콜 | 포트 | 소스/대상 |
|------|----------|------|-----------|
| In | TCP | 3306 | Web EC2 SG |
| In | TCP | 5432 | Web EC2 SG (선택, PostgreSQL 사용 시) |
| Out | All | All | `0.0.0.0/0` (또는 제한 가능) |

**공통 수락 기준**

1. Web EC2가 인터넷 CIDR로부터 직접 80/443을 받지 않는다.
2. Bastion SSH가 `my_ip` 외에서 거부된다.
3. DB 포트가 Web SG 외에서 거부된다.
4. SG 간 참조는 ID/리소스 참조로 연결된다 (하드코딩 SG ID 금지).

**추가 권장 (S2, P1)**  
Bastion → Web EC2 SSH(22) 허용 규칙을 Web SG에 추가할 수 있다. 추가 시 명세에 반영하고 “운영 점프 경로”로 문서화한다.

---

### F-IAC-01 변수·로컬·출력

| 항목 | 내용 |
|------|------|
| 목적 | 환경별 재사용·가시성 |
| 우선순위 | P0 / S1 |

**필수 변수**

- `aws_region`, `environment`, `project_name`
- `vpc_cidr`, 서브넷 CIDR 리스트
- `my_ip` (CIDR 형식 검증)

**필수/권장 출력**

- `vpc_id`
- public / private_web / private_db subnet IDs
- security group IDs (map)
- nat gateway public IPs

**수락 기준**

1. `terraform.tfvars.example`이 제공된다.
2. `terraform.tfvars`는 Git에 포함되지 않는다.
3. `terraform output`으로 주요 값이 조회된다.

---

### F-IAC-02 로컬 State 및 Destroy

| 항목 | 내용 |
|------|------|
| 목적 | 학습·테스트 수명주기 |
| 우선순위 | P0 / S1 |

**수락 기준**

1. `terraform apply` 후 `terraform destroy`가 의존성 오류 없이 완료된다.
2. `*.tfstate*` 가 `.gitignore`에 포함된다.
3. destroy 후 콘솔에서 본 프로젝트 태그 리소스가 잔존하지 않는다 (수동 잔여 점검).

---

### F-IAC-03 Remote State (S3 + DynamoDB)

| 항목 | 내용 |
|------|------|
| 목적 | 팀/CI 동시 수정 방지, state 중앙화 |
| 우선순위 | P1 / S1 후반~S3 |

**수락 기준**

1. S3 버킷에 state 저장, DynamoDB로 lock.
2. 로컬 전환 절차가 문서화되어 있다.
3. state 버킷 퍼블릭 액세스 차단.

---

## 5. 상세 기능 명세 — Stage 2 (컴퓨팅·LB)

### F-CMP-01 Bastion Host

| 항목 | 내용 |
|------|------|
| 목적 | Private 리소스 관리용 점프 서버 |
| 우선순위 | P0 / S2 |
| 배치 | Public 서브넷 |
| OS | Ubuntu 22.04 LTS 권장 |
| 접근 | SSH 22, 소스 `my_ip` |

**수락 기준**

1. 개발자 공인 IP에서 SSH 성공.
2. 다른 IP에서 SSH 실패(타임아웃/거부).
3. Bastion에 불필요한 0.0.0.0/0 SSH 규칙이 없다.

---

### F-CMP-02 Web EC2

| 항목 | 내용 |
|------|------|
| 목적 | 실제 웹 트래픽 처리 |
| 우선순위 | P0 / S2 |
| 배치 | Private Web 서브넷, **최소 2대(AZ별 1)** 권장 |
| 네트워크 | 공인 IP 없음(또는 불필요), ALB 경유만 |

**수락 기준**

1. 인스턴스가 Private 서브넷에 있다.
2. 인터넷에서 인스턴스 IP로 직접 HTTP 접근 불가.
3. 아웃바운드(예: `apt`/`curl` 외부)가 NAT 경로로 가능.

---

### F-CMP-03 ALB + Target Group + Health Check

| 항목 | 내용 |
|------|------|
| 목적 | 2-AZ 부하 분산 및 장애 인스턴스 제외 |
| 우선순위 | P0 / S2 |
| 배치 | Public 서브넷 (다중 AZ) |
| 리스너 | HTTP 80 (HTTPS 443은 인증서 준비 시 P1) |
| TG | Web EC2 등록 |
| Health Check | 경로 예: `/` 또는 `/health` (앱에 맞게 고정) |

**수락 기준**

1. ALB DNS로 HTTP 200(또는 의도한 코드) 응답.
2. 한쪽 타깃 unhealthy 시 나머지 타깃으로 서비스 유지.
3. SG 체인이 ALB → Web 만 허용.

---

### F-CMP-04 Nginx / 앱 자동 기동

| 항목 | 내용 |
|------|------|
| 목적 | 인스턴스 생성 직후 웹 서비스 가능 상태 |
| 우선순위 | P1 / S2 |
| 방식 | Terraform `user_data` 우선 / Ansible 선택 |
| 런타임 | Nginx + (Node.js **또는** Spring Boot 중 택 1) |

**수락 기준**

1. 최초 부팅 후 Health Check 경로가 healthy가 된다 (타임아웃 내).
2. 재부팅 후에도 서비스 자동 기동(systemd enable 등).
3. 부트스트랩 스크립트가 저장소에 버전 관리된다.

---

### F-CMP-05 RDS/DB (선택)

| 항목 | 내용 |
|------|------|
| 목적 | DB 계층 실물 검증 |
| 우선순위 | P2 / S2 |
| 배치 | Private DB 서브넷, Multi-AZ는 선택 |
| 접속 | Web EC2 SG → 3306만 |

**수락 기준**

1. 퍼블릭 액세스 비활성.
2. Web EC2에서만 접속 성공, Bastion/외부 직접 접속 실패(의도된 경우).
3. destroy 시 스냅샷 잔여 정책이 문서화되어 있다.

> S1만으로도 “DB 서브넷·SG 공간 확보”는 PRD를 충족한다. F-CMP-05는 실물 DB가 필요할 때 구현한다.

---

## 6. 상세 기능 명세 — Stage 3 (CI/CD)

### F-CICD-01 Lint / Validate

| 항목 | 내용 |
|------|------|
| 트리거 | PR 오픈/업데이트, push (정책에 따라) |
| 동작 | `terraform fmt -check`, `terraform validate` |
| 우선순위 | P0 / S3 |

**수락 기준**

1. 포맷 오류 시 파이프라인 실패.
2. 문법 오류 시 파이프라인 실패.
3. 성공 시 다음 job으로 진행.

---

### F-CICD-02 Plan

| 항목 | 내용 |
|------|------|
| 동작 | `terraform plan` (가능 시 아티팩트/PR 코멘트) |
| 우선순위 | P0 / S3 |

**수락 기준**

1. AWS 인증 성공 후 plan 실행.
2. plan 결과가 로그 또는 코멘트로 확인 가능.
3. apply는 이 job에서 자동 수행하지 않는다 (분리).

---

### F-CICD-03 Apply

| 항목 | 내용 |
|------|------|
| 트리거 | `main` 머지 등 보호된 이벤트 |
| 우선순위 | P1 / S3 |
| 통제 | environment protection / manual approval 권장 |

**수락 기준**

1. plan과 분리된 job/workflow이다.
2. 보호되지 않은 브랜치에서 무분별 apply 되지 않는다.
3. apply 성공/실패가 Actions 로그에 남는다.

---

### F-CICD-04 레거시 EC2 애플리케이션 배포

| 항목 | 내용 |
|------|------|
| 우선순위 | **P2** / S3 (PRD v1.1: 최종 경로는 EKS) |
| 옵션 | S3+CodeDeploy 또는 Bastion SSH → Private EC2 |

**수락 기준:** 레거시 경로를 구현한 경우에만 적용. 기본 권장은 **F-EKS-09/10**.

---

### F-CICD-05 시크릿·OIDC

| 항목 | 내용 |
|------|------|
| 우선순위 | P0 / S3 |
| 금지 | 리포지토리 코드/로그에 Access Key 평문 커밋 |
| 권장 | GitHub OIDC → AWS IAM Role |
| 최소 | GitHub Secrets에 키 저장 (OIDC 전 임시) |

**수락 기준**

1. 워크플로 YAML에 장기 키가 하드코딩되어 있지 않다.
2. 인증 방식이 README에 설명되어 있다.
3. `.gitignore`에 `*.tfvars`, state, 키 파일이 포함된다.

---

## 7. 상세 기능 명세 — Stage 4 (EKS)

PRD §14 (EKS-IN-*) 와 1:1로 대응한다.

### F-EKS-01 EKS 클러스터

| 항목 | 내용 |
|------|------|
| 우선순위 | P0 / S4 |
| 입력 | 기존 VPC ID, Private/Public 서브넷, 클러스터 버전 |
| 동작 | Terraform으로 EKS 클러스터 생성 (권장 A) |
| 출력 | cluster name, endpoint, OIDC issuer |

**수락 기준**

1. 클러스터 status = `ACTIVE`.
2. Stage 1 VPC를 재사용한다 (별도 VPC 기본 금지).
3. 리전 `ap-northeast-2`.

---

### F-EKS-02 관리형 노드 그룹

| 항목 | 내용 |
|------|------|
| 우선순위 | P0 / S4 |
| 배치 | **Private Web 서브넷**, desired ≥ 2, AZ 분산 권장 |
| 인스턴스 | t3.small 또는 t3.medium (구현 시 문서 고정) |

**수락 기준**

1. `kubectl get nodes` Ready ≥ 2.
2. 노드 인스턴스가 Private 서브넷에 있다.
3. 노드에 불필요 공인 SSH(0.0.0.0/0) 없음.

---

### F-EKS-03 클러스터 접근

**수락 기준**

1. `aws eks update-kubeconfig --name <cluster> --region ap-northeast-2` 성공.
2. `kubectl get ns` 성공.
3. 접근 경로(로컬 IAM / Bastion / CI OIDC)가 README에 명시.

---

### F-EKS-04 AWS Load Balancer Controller + IRSA

**수락 기준**

1. Controller Pod Running.
2. IRSA(서비스 계정 → IAM 역할) 연결됨.
3. Ingress 생성 시 **ALB**가 프로비저닝된다.

---

### F-EKS-05 샘플 워크로드 (Deploy / Svc / Ingress)

**수락 기준**

1. Deployment replicas ≥ 1 (권장 2).
2. Service + Ingress 매니페스트가 저장소에 버전 관리됨.
3. Ingress에 ALB ADDRESS가 할당됨.

---

### F-EKS-06 E2E HTTP

**수락 기준**

1. 인터넷에서 `http://<ALB-DNS>/` (또는 `/health`) 의도 응답.
2. 노드 Private IP로 인터넷 직접 HTTP 불가.
3. PRD §14.6 데모 체크리스트 통과.

---

### F-EKS-07 Destroy / 비용 회수

**수락 기준**

1. 삭제 순서 문서: 앱/Ingress → 애드온 → 노드/클러스터 → (네트워크).
2. 삭제 후 EKS 클러스터·관련 ALB 잔존 없음(콘솔 확인).
3. NFR-9 준수.

---

### F-EKS-08 ~ F-EKS-10 (P1)

| ID | 내용 | 수락 기준 요약 |
|----|------|----------------|
| F-EKS-08 | ECR 리포 | 이미지 push 가능 |
| F-EKS-09 | CI build/push | Actions 성공 로그 |
| F-EKS-10 | CD kubectl/Helm | 배포 후 ALB 응답 유지/갱신 |

---

## 8. 문서화 기능

### F-DOC-01 README 및 아키텍처

**수락 기준**

1. 아키텍처 다이어그램에 **네트워크 + EKS 트래픽 경로** 포함.
2. `init` → `plan` → `apply` → `destroy` 및 **EKS 삭제 순서** 기재.
3. `my_ip` 설정 방법 기재.
4. 단계별 현황(S1~S4) 표기.
5. PRD·본 명세서로 링크.

---

## 9. 데이터·구성 값 (기준 프로파일)

| 키 | 기본값 |
|----|--------|
| Region | `ap-northeast-2` |
| AZ | `ap-northeast-2a`, `ap-northeast-2c` |
| VPC | `10.0.0.0/16` |
| environment | `dev` |
| project_name | `cloud-infra` |
| EKS 노드 | managed, desired=2, Private Web |
| Ingress Health | `/` 또는 `/health` (구현 시 하나로 고정) |

---

## 10. 트래픽·보안 시나리오 테스트 케이스

| TC ID | 시나리오 | 기대 결과 | 단계 |
|-------|----------|-----------|------|
| TC-01 | 인터넷 → ALB → **Pod** | 웹 응답 성공 | **S4** |
| TC-02 | 인터넷 → 노드 private IP:80 | 실패 | S4 |
| TC-03 | my_ip → Bastion:22 | SSH 성공 | S2 |
| TC-04 | 다른 IP → Bastion:22 | 실패 | S2 |
| TC-05 | 노드/Pod → 외부 (ECR 등) | NAT 경유 성공 | S1~S4 |
| TC-06 | 외부 → RDS:3306 | 실패 | S1~S2 |
| TC-07 | Pod/EC2 → RDS:3306 | 성공 (DB 구현 시) | S2/S4 P2 |
| TC-08 | PR에 잘못된 tf | CI validate 실패 | S3 |
| TC-09 | 정상 PR | CI plan 성공 | S3 |
| TC-10 | destroy 후 과금 리소스 | NAT/ALB/**EKS** 삭제 확인 | S1~S4 |
| TC-11 | `kubectl get nodes` | Ready ≥ 2 | S4 |
| TC-12 | (P1) Actions ECR+deploy | job 성공, 앱 응답 | S4 |

---

## 11. 단계별 완료 정의 (DoD)

### Stage 1 DoD

- [ ] F-NET-01 ~ F-NET-04, F-SEC-01 ~ F-SEC-04, F-IAC-01, F-IAC-02 충족
- [ ] NAT 2 + RT 5 (PRD 권장 HA)
- [ ] `terraform validate` 성공
- [ ] 시크릿·tfvars 미커밋

### Stage 2 DoD

- [ ] F-CMP-01 Bastion 충족
- [ ] (P2) 레거시 F-CMP-02~04는 선택

### Stage 3 DoD

- [ ] F-CICD-01, F-CICD-02, F-CICD-05 충족
- [ ] TC-08, TC-09 통과

### Stage 4 DoD (EKS) — **G-6**

- [ ] F-EKS-01 ~ F-EKS-07 충족
- [ ] TC-01, TC-02, TC-11 통과
- [ ] (P1) F-EKS-08~10, TC-12
- [ ] README EKS 경로·destroy 런북

### 프로젝트 전체 DoD

- [ ] PRD 섹션 9 성공 지표 충족
- [ ] 본 명세서 **P0** (네트워크 + EKS 최소선) 충족
- [ ] 데모 스크립트 README 존재

---

## 12. 명시적 비기능 (구현 시 준수)

| ID | 규칙 |
|----|------|
| IMPL-1 | 리소스 이름·태그에 `project` / `environment` 포함 |
| IMPL-2 | destroy 실패 유발 의존성 자제 |
| IMPL-3 | SG 규칙에 description |
| IMPL-4 | NAT, ALB, EIP, RDS, **EKS 컨트롤 플레인**, 노드 과금 고지 |
| IMPL-5 | `required_providers` 버전 명시 |
| IMPL-6 | EKS 삭제 시 Ingress/ALB 잔존 점검 |

---

## 13. 추적성 매트릭스 (PRD Goals ↔ Features)

| PRD Goal | 관련 기능 |
|----------|-----------|
| G-1 네트워크 설계 | F-NET-*, F-SEC-* |
| G-2 IaC 변경 관리 | F-IAC-*, F-CICD-01~03, F-EKS-01~02 |
| G-3 CI/CD | F-CICD-*, F-EKS-09~10 |
| G-4 보안 | F-SEC-*, F-CICD-05, F-CMP-01, F-EKS-02/04 |
| G-5 비용 통제 | F-IAC-02, F-EKS-07, destroy 런북 |
| **G-6 EKS** | **F-EKS-01 ~ F-EKS-07 (P0)** |

---

## 14. 권장 구현 순서 (실행 체크리스트)

1. S1 네트워크 (NAT 2, RT 5) → validate/plan  
2. S2 Bastion (레거시 EC2 웹은 건너뛰어도 됨)  
3. S3 Terraform Actions (fmt/validate/plan) + OIDC  
4. S4 EKS 클러스터 + 노드  
5. LB Controller + 샘플 Ingress E2E  
6. (P1) ECR + Actions 배포  
7. destroy 리허설  
8. README·다이어그램 최종화  

---

## 15. 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | 2026-07-16 | 초판 — PRD·기존 docs 통합 |
| **v1.1** | **2026-07-16** | **PRD EKS 권장 A 반영: S4, F-EKS-*, 레거시 EC2 P2, TC-11/12** |
