# EKS 설계 (PRD 권장 A)

## 트래픽

```
Internet → ALB (Public) → AWS LB Controller Ingress
        → Service → Pod (Private Web 노드)
```

## Terraform 리소스 맵

| 파일 | 내용 | 조건 |
|------|------|------|
| `eks.tf` | 클러스터, 관리형 노드 그룹 | `enable_eks` |
| `iam_eks.tf` | 클러스터/노드 롤, OIDC, LB Controller IRSA | `enable_eks` |
| `ecr.tf` | FE/BE 리포 | `enable_ecr` 또는 `enable_eks` |
| `subnets.tf` | ELB/internal-elb·cluster 태그 | 항상 |
| `policies/aws-load-balancer-controller-iam-policy.json` | Controller IAM | 정책 파일 |

## 기본값

| 항목 | 값 |
|------|-----|
| 클러스터 이름 | `{project}-{env}-eks` → `cloud-infra-dev-eks` |
| 버전 | 1.29 (변수로 변경) |
| 노드 | t3.medium, desired/min 2, max 4, **Private Web** |
| API | Public+Private, Public CIDR 기본 = `my_ip` |
| 이미지 레지스트리 | ECR `{prefix}-fe`, `{prefix}-be` |

## 적용 순서

1. Stage 1 네트워크 apply (`enable_eks=false` 권장으로 먼저 검증 가능)
2. `enable_eks=true` plan/apply
3. `aws eks update-kubeconfig ...`
4. `k8s/aws-load-balancer-controller/install.md`
5. ECR 푸시 → `k8s/` 매니페스트 이미지 교체 → apply
6. Ingress ALB DNS 확인

## Destroy 순서

1. Ingress/앱 매니페스트 삭제 (ALB 정리)
2. Helm LB Controller 제거
3. `terraform destroy` 또는 `enable_eks=false` 후 apply로 EKS 제거
4. 콘솔에서 고아 ALB/SG 점검

## 비용 주의

- EKS 컨트롤 플레인: **클러스터 유지 시간 과금** (노드 0이어도)
- 노드 EC2 + NAT×2 + ALB
- 데모 후 **당일 삭제** 권장
