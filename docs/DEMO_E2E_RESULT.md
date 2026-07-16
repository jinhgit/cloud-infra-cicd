# EKS E2E 실전 결과 (요약)

| 항목 | 결과 |
|------|------|
| 날짜 | 2026-07-17 (KST) |
| 구성 | Stage1 네트워크 + **Bastion** + **EKS 1.32** + ALB Ingress |
| 노드 | t3.small ×2 (Private Web), Ready |
| 트래픽 | Internet → ALB → FE/BE Pod **200 OK** |
| Bastion | SSH/SSM 유지 (점프 서버 스토리) |
| 스크린샷 | [docs/demo/](demo/README.md) |

![E2E 터미널](demo/screenshots/03-eks-e2e-terminal.png)

## 검증 curl (성공 시)

```bash
export ALB_DNS=$(kubectl -n cloud-infra get ingress cloud-infra -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -sS -o /dev/null -w "%{http_code}\n" "http://${ALB_DNS}/"          # 200
curl -sS "http://${ALB_DNS}/health"                                      # status ok
curl -sS "http://${ALB_DNS}/api/hello"                                   # Hello from BE
```

## 트러블슈팅에서 반영한 수정

1. EKS 버전 **1.29 → 1.32** (unsupported)
2. 노드 타입 **t3.medium → t3.small** (Free Tier 계정 제한)
3. 이미지 **`--platform linux/amd64`** (Mac arm64 vs 노드 x86_64)
4. LB Controller IAM 정책 **v2.13** 로 갱신 (`DescribeListenerAttributes` 등)

## 비용

실습 후 반드시:

```bash
kubectl delete -f k8s/ingress/ --ignore-not-found
helm uninstall aws-load-balancer-controller -n kube-system || true
cd terraform && terraform destroy -auto-approve
```
