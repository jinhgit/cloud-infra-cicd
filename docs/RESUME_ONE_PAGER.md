# 이력서·포트폴리오 원페이지

> 노션/이력서에 **복사**하거나 PDF 1장으로 쓸 요약본입니다.  
> 저장소: https://github.com/jinhgit/cloud-infra-cicd

---

## 프로젝트 한 줄

**Terraform 기반 3-Tier AWS 네트워크 + Bastion/SSM + EKS(ALB Ingress) + GitHub Actions CI**  
평소는 Docker로 무과금 개발, 클라우드 유료 리소스는 이중 확인 후 짧은 데모·즉시 destroy.

---

## 역할 / 기간

| 항목 | 내용 |
|------|------|
| 역할 | 설계 · IaC · 앱 컨테이너 · CI · 문서 (1인) |
| 스택 | AWS, Terraform, EKS, ALB, ECR, VPC, GitHub Actions, Docker, Node.js, Nginx |
| 리전 | ap-northeast-2 |

---

## 핵심 성과 (불릿 · 이력서 복붙용)

- **2-AZ 3-Tier VPC**를 Terraform으로 코드화 (Public/Web/DB 서브넷 6, NAT·RT·SG 최소 권한)
- **Bastion** 구축 (SSH my_ip 제한 + **SSM Session Manager**, IMDSv2, 암호화 볼륨)
- **EKS 1.32** Managed Node (Private) + **AWS LB Controller(IRSA)** 로 Ingress → **ALB** 경로 검증  
  (`/` FE, `/health`·`/api/*` BE, HTTP 200 E2E 성공)
- FE/BE **Docker**화, same-origin API, health/version/gitSha, Compose 통합 테스트
- GitHub Actions: **test · amd64 이미지 빌드 · Compose 통합 · terraform fmt/validate/plan · PR plan 코멘트**
- **비용·보안 가드**: `acknowledge_paid_aws` + `confirm_paid_apply` 이중 확인, AI/자동화 apply 금지 규칙, 기본 무료 모드
- 실전 이슈 해결: EKS 버전 지원, Free Tier 인스턴스 타입, **linux/amd64** 이미지, Controller IAM 정책 갱신

---

## 아키텍처 (텍스트)

```text
Internet → ALB (Public) → Ingress → FE/BE Pods (Private Nodes)
Developer → Bastion (SSH/SSM)
CI → GitHub Actions (plan/test/build, no apply)
Daily → Docker Compose (zero AWS cost)
```

스크린샷: `docs/demo/README.md`

---

## 기술 키워드 (ATS/검색)

`AWS` `Terraform` `VPC` `NAT Gateway` `Security Group` `EKS` `ALB` `Ingress` `IRSA`  
`ECR` `Bastion` `SSM` `GitHub Actions` `OIDC` `Docker` `CI/CD` `IaC` `Least Privilege`

---

## 링크

| 구분 | URL |
|------|-----|
| GitHub | https://github.com/jinhgit/cloud-infra-cicd |
| 데모 세트 | docs/demo/README.md |
| E2E 결과 | docs/DEMO_E2E_RESULT.md |
| 무료 모드 | docs/FREE_MODE.md |
| 면접 Q&A | docs/INTERVIEW_QA_LESSONS.md |
| OIDC 설정 | docs/OIDC_SETUP.md |

---

## 이력서 문장 예시 (완성형)

> AWS 서울 리전에서 Terraform으로 다중 AZ 3-Tier 네트워크와 Bastion을 구성하고, EKS Private 노드 위 FE/BE 워크로드를 ALB Ingress로 노출하는 경로를 E2E 검증함. GitHub Actions로 테스트·이미지 빌드·Terraform plan을 자동화하고, 과금 리소스는 이중 확인 후에만 생성·즉시 destroy 하는 비용 통제 체계를 적용함.

---

## 면접 시 강조 3가지

1. **설계 이유** (Private 노드, SG, NAT HA vs 비용)  
2. **실전 트러블슈팅** (버전·Free Tier·플랫폼·IAM)  
3. **운영 의식** (무료 기본, 유료 확인, destroy)  
