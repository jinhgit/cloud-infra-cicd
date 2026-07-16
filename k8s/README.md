# k8s 매니페스트 (EKS 배포용)

PRD 권장 A 경로:

```
Internet → ALB (AWS Load Balancer Controller) → Ingress → Service → Pod
```

**데모 당일 전체 순서(인프라→ECR→배포→destroy):**  
→ [docs/EKS_E2E_CHECKLIST.md](../docs/EKS_E2E_CHECKLIST.md)

## 디렉터리

```
k8s/
├── namespace.yaml
├── be/                 # Backend API
│   ├── deployment.yaml
│   └── service.yaml
├── fe/                 # Frontend (Nginx static)
│   ├── deployment.yaml
│   └── service.yaml
├── ingress/
│   └── ingress.yaml    # 단일 ALB Ingress
└── aws-load-balancer-controller/
    └── install.md      # IRSA + Helm 설치 절차
```

## 적용 순서 (클러스터 Ready 후 · 스크립트)

```bash
# 1) kubeconfig
aws eks update-kubeconfig --region ap-northeast-2 --name cloud-infra-dev-eks

# 2) AWS LB Controller — aws-load-balancer-controller/install.md

# 3) 이미지 (amd64) — ECR 푸시는 유료 소액 가능, 확인 후
#    ./scripts/build-images.sh
#    CONFIRM_ECR_PUSH=yes ./scripts/build-push-images.sh

# 4) 매니페스트 렌더 + 배포
export ECR_BE=... ECR_FE=...   # 또는 terraform output
./scripts/render-k8s-images.sh
./scripts/deploy-k8s.sh

# 5) ALB
kubectl -n cloud-infra get ingress
```

## 이미지 플레이스홀더

매니페스트의 `IMAGE_FE`, `IMAGE_BE` 를 ECR URL로 바꿉니다.

```bash
# Terraform output 예
terraform -chdir=terraform output ecr_repository_urls
```

예: `447170313588.dkr.ecr.ap-northeast-2.amazonaws.com/cloud-infra-dev-be:latest`

## 삭제 순서 (비용)

1. `kubectl delete -f k8s/ingress/` (ALB 제거 대기)
2. `kubectl delete -f k8s/fe/ -f k8s/be/ -f k8s/namespace.yaml`
3. LB Controller uninstall
4. `terraform destroy` (또는 enable_eks=false 후 apply)
