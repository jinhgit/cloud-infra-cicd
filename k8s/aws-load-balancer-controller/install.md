# AWS Load Balancer Controller 설치

Terraform `enable_eks=true` apply 후 출력:

```bash
cd terraform
terraform output aws_lb_controller_role_arn
terraform output eks_cluster_name
```

## 1. Helm repo

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

## 2. ServiceAccount + IRSA

```bash
CLUSTER_NAME=$(terraform -chdir=../../terraform output -raw eks_cluster_name)
ROLE_ARN=$(terraform -chdir=../../terraform output -raw aws_lb_controller_role_arn)
VPC_ID=$(terraform -chdir=../../terraform output -raw vpc_id)
REGION=ap-northeast-2

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${ROLE_ARN}
EOF

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=${REGION} \
  --set vpcId=${VPC_ID}
```

## 3. 확인

```bash
kubectl -n kube-system get deploy aws-load-balancer-controller
kubectl -n kube-system logs -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50
```

## 4. 앱 Ingress

`../ingress/ingress.yaml` 적용 후:

```bash
kubectl -n cloud-infra get ingress cloud-infra
# ADDRESS 컬럼의 ALB DNS 로 curl
```
