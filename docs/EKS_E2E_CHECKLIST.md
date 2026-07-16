# EKS E2E 실행 체크리스트 (권장 A)

**목표:** 인터넷 → ALB → Ingress → Pod (FE/BE) 응답까지 한 번에 검증하고, **당일 destroy** 로 비용을 끊는다.

| 항목 | 값 |
|------|-----|
| 예상 소요 | **2.5~4시간** (대기·트러블슈팅 포함) |
| 리전 | `ap-northeast-2` |
| 클러스터명 (기본) | `cloud-infra-dev-eks` |
| 관련 문서 | [EKS_DESIGN.md](EKS_DESIGN.md), [k8s/README.md](../k8s/README.md), [STAGE_1_APPLY.md](STAGE_1_APPLY.md) |

```
Internet → ALB (Public)
        → AWS Load Balancer Controller (Ingress)
        → Service → Pod (Private Web 노드)
```

---

## 0. 사전 준비 (로컬, 비용 0)

### 0-1. 도구

```bash
terraform version    # >= 1.5
aws --version
kubectl version --client
helm version
docker version
```

없으면 설치: AWS CLI, kubectl, Helm 3, Docker Desktop.

### 0-2. AWS·IP

```bash
aws sts get-caller-identity
# 공인 IP 확인 후 terraform.tfvars 의 my_ip 에 x.x.x.x/32 설정
curl -s https://checkip.amazonaws.com
```

### 0-3. 로컬 앱·이미지 스모크 (권장)

```bash
# 저장소 루트
docker compose up --build -d
curl -sS http://localhost:8080/health | head -c 200; echo
curl -sS http://localhost:8080/api/hello | head -c 200; echo
docker compose down
```

- [ ] Compose 로 FE 프록시 `/health`, `/api/hello` 200  
- [ ] `BE` `npm test` 통과 (선택)

### 0-4. tfvars

```bash
cd terraform
# 없으면: cp terraform.tfvars.example terraform.tfvars
# my_ip 확인
```

데모 당일 EKS 켤 값 (apply 직전에 수정해도 됨):

```hcl
enable_eks = true
# enable_ecr 은 enable_eks=true 이면 자동 생성됨 (ecr.tf)
```

- [ ] `my_ip` 가 현재 공인 IP  
- [ ] 데모 **시작 직전** 까지 `enable_eks=false` 유지 권장 (비용)

---

## 1. 인프라: 네트워크 + EKS + ECR

> ⏱ 대략 **15~25분** (EKS 클러스터·노드 생성 대기)

### 1-A. (선택) 네트워크만 먼저

안정성 우선 시 2-step.

```bash
cd terraform
# enable_eks = false
terraform init
terraform plan -out=tfplan-net
terraform apply tfplan-net
terraform output deployment_summary
```

- [ ] `nat_gateways = 2`, 서브넷 6  

### 1-B. EKS 포함 apply (데모 본 경로)

```bash
cd terraform

# terraform.tfvars
#   enable_eks = true

terraform plan -out=tfplan-eks
# plan 에 eks_cluster, node_group, ecr, iam 역할이 보이는지 확인
terraform apply tfplan-eks
```

### 1-C. 출력 저장 (이후 명령에서 사용)

```bash
cd terraform
export AWS_REGION=ap-northeast-2
export CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
export VPC_ID=$(terraform output -raw vpc_id)
export LB_ROLE_ARN=$(terraform output -raw aws_lb_controller_role_arn)
export ECR_FE=$(terraform output -json ecr_repository_urls | jq -r .fe)
export ECR_BE=$(terraform output -json ecr_repository_urls | jq -r .be)
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "CLUSTER=$CLUSTER_NAME"
echo "ECR_FE=$ECR_FE"
echo "ECR_BE=$ECR_BE"
echo "LB_ROLE=$LB_ROLE_ARN"
```

- [ ] `CLUSTER_NAME` = `cloud-infra-dev-eks` (또는 설정한 이름)  
- [ ] ECR FE/BE URL 출력됨  
- [ ] `LB_ROLE_ARN` 비어 있지 않음  

### 1-D. 클러스터 상태

```bash
aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
  --query 'cluster.status' --output text
# ACTIVE 가 될 때까지 대기 (생성 직후면 수분)

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
kubectl get nodes -o wide
```

- [ ] `status` = **ACTIVE**  
- [ ] 노드 **Ready ≥ 2**  
- [ ] 노드 IP 가 Private 대역 (10.0.10.x / 10.0.11.x 근처)  

**실패 시**

| 증상 | 조치 |
|------|------|
| API timeout | `my_ip` 와 현재 공인 IP 불일치 → tfvars 수정 후 apply |
| 노드 NotReady | CNI/IAM 확인, `kubectl describe node` |
| Unauthorized | `update-kubeconfig` 재실행, IAM 사용자에 EKS 권한 |

---

## 2. AWS Load Balancer Controller

> ⏱ 대략 **5~10분**

저장소 루트 또는 `k8s/` 기준. 아래는 **저장소 루트** 기준.

```bash
# 환경 변수는 1-C 에서 export 했다고 가정
# 없으면 terraform -chdir=terraform output 으로 다시 설정

helm repo add eks https://aws.github.io/eks-charts
helm repo update

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${LB_ROLE_ARN}
EOF

helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=${AWS_REGION} \
  --set vpcId=${VPC_ID}

kubectl -n kube-system rollout status deploy/aws-load-balancer-controller --timeout=120s
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
```

- [ ] Controller Pod **Running**  
- [ ] 로그에 반복 Fatal/AccessDenied 없음  

```bash
kubectl -n kube-system logs -l app.kubernetes.io/name=aws-load-balancer-controller --tail=30
```

**실패 시**

| 증상 | 조치 |
|------|------|
| WebIdentity / AssumeRole 오류 | SA annotation 의 Role ARN, OIDC provider 확인 |
| subnet 관련 오류 | Public 서브넷 `kubernetes.io/role/elb=1` 태그 (Terraform subnets.tf) |

---

## 3. 이미지 빌드 → ECR 푸시

> ⏱ 대략 **5~15분**

```bash
export AWS_REGION=ap-northeast-2
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR 로그인
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# 저장소 루트에서 빌드
docker build -t "${ECR_BE}:latest" ./BE
docker build -t "${ECR_FE}:latest" ./FE

docker push "${ECR_BE}:latest"
docker push "${ECR_FE}:latest"

# 확인
aws ecr describe-images --repository-name cloud-infra-dev-be --region "$AWS_REGION" \
  --query 'imageDetails[-1].imageTags' --output text
aws ecr describe-images --repository-name cloud-infra-dev-fe --region "$AWS_REGION" \
  --query 'imageDetails[-1].imageTags' --output text
```

- [ ] BE/FE `latest` 푸시 성공  
- [ ] 노드가 Private 이므로 **ECR pull 은 NAT 경유** (NAT 없으면 ImagePullBackOff)

---

## 4. 매니페스트 이미지 치환 후 배포

> ⏱ 대략 **5~15분** (ALB 프로비저닝 포함 **최대 ~5분** 추가)

### 4-A. 이미지 치환 (커밋하지 않는 임시 파일 권장)

```bash
# 저장소 루트
export ECR_BE ECR_FE   # 1-C / 3 단계 값

# 작업용 복사본
mkdir -p /tmp/k8s-deploy
cp -R k8s /tmp/k8s-deploy/
# macOS sed
sed -i '' "s|IMAGE_BE|${ECR_BE}:latest|g" /tmp/k8s-deploy/k8s/be/deployment.yaml
sed -i '' "s|IMAGE_FE|${ECR_FE}:latest|g" /tmp/k8s-deploy/k8s/fe/deployment.yaml

# Linux 는: sed -i "s|IMAGE_BE|...|g" ...
grep -n "image:" /tmp/k8s-deploy/k8s/be/deployment.yaml /tmp/k8s-deploy/k8s/fe/deployment.yaml
```

- [ ] `IMAGE_BE` / `IMAGE_FE` 플레이스홀더 잔존 없음  

### 4-B. 적용

```bash
kubectl apply -f /tmp/k8s-deploy/k8s/namespace.yaml
kubectl apply -f /tmp/k8s-deploy/k8s/be/
kubectl apply -f /tmp/k8s-deploy/k8s/fe/
kubectl apply -f /tmp/k8s-deploy/k8s/ingress/

kubectl -n cloud-infra get deploy,po,svc,ing -o wide
kubectl -n cloud-infra rollout status deploy/be --timeout=180s
kubectl -n cloud-infra rollout status deploy/fe --timeout=180s
```

- [ ] Pod **Running / Ready**  
- [ ] Service `be`, `fe` 존재  
- [ ] Ingress `ADDRESS` 에 ALB DNS 할당 (수 분 소요 가능)  

```bash
# ADDRESS 나올 때까지
kubectl -n cloud-infra get ingress cloud-infra -w
# Ctrl+C 로 중단 후
export ALB_DNS=$(kubectl -n cloud-infra get ingress cloud-infra -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB_DNS=$ALB_DNS"
```

**실패 시**

| 증상 | 조치 |
|------|------|
| ImagePullBackOff | ECR 권한·URL·NAT · **이미지 플랫폼(amd64)** |
| Ingress ADDRESS 공백 | Controller 로그, 서브넷 태그, **IAM 정책 최신화** (`DescribeListenerAttributes` 등) |
| CrashLoop | `kubectl -n cloud-infra logs deploy/be` |
| 노드 ASG Free Tier 오류 | `eks_node_instance_type` 을 `t3.small`/`t3.micro` 등 적격 타입으로 |
| EKS version unsupported | `eks_cluster_version` 을 리전 지원 버전으로 (예: 1.32) |

---

## 5. E2E 검증 (성공 기준)

> PRD G-6 / §14.6 대응

```bash
export ALB_DNS=$(kubectl -n cloud-infra get ingress cloud-infra -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# FE 헬스 (Ingress / → fe, /healthz 는 fe 경로 — 현재 Ingress 는 / 가 fe)
curl -sS -o /dev/null -w "FE root HTTP %{http_code}\n" "http://${ALB_DNS}/"

# BE health (Ingress path /health → be)
curl -sS "http://${ALB_DNS}/health"
echo
curl -sS -o /dev/null -w "BE /health HTTP %{http_code}\n" "http://${ALB_DNS}/health"

# BE hello
curl -sS "http://${ALB_DNS}/api/hello"
echo
curl -sS -o /dev/null -w "BE /api/hello HTTP %{http_code}\n" "http://${ALB_DNS}/api/hello"

# FE healthz — path / 아래가 아니면 직접 fe 서비스는 클러스터 내부만
# Ingress 에 /healthz 없음: 브라우저 루트 HTML 확인 또는
curl -sS -o /dev/null -w "HTML %{http_code}\n" "http://${ALB_DNS}/"
```

### 체크리스트 (데모 통과 조건)

- [ ] `kubectl get nodes` → Ready ≥ 2  
- [ ] `kubectl -n cloud-infra get pods` → be/fe Running  
- [ ] `http://$ALB_DNS/` → **200** (FE HTML)  
- [ ] `http://$ALB_DNS/health` → **200** + `"status":"ok"`  
- [ ] `http://$ALB_DNS/api/hello` → **200** + Hello 메시지  
- [ ] 노드 Private IP 로 인터넷 직접 접속 불가 (의도)  

브라우저: `http://<ALB_DNS>/` 열어 health/hello 카드가 OK 인지 확인  
(FE 가 same-origin 으로 `/health`, `/api/hello` 호출).

---

## 6. 정리 (비용 차단) — **필수**

> 순서 지키지 않으면 ALB/SG 가 남아 과금될 수 있음.

### 6-1. 앱·Ingress (ALB 삭제 유도)

```bash
kubectl delete -f /tmp/k8s-deploy/k8s/ingress/ --ignore-not-found
# ALB 가 사라질 때까지 2~5분 대기
aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query "LoadBalancers[?contains(LoadBalancerName,'k8s') || contains(LoadBalancerName,'cloud')].[LoadBalancerName,State.Code]" \
  --output table

kubectl delete -f /tmp/k8s-deploy/k8s/fe/ --ignore-not-found
kubectl delete -f /tmp/k8s-deploy/k8s/be/ --ignore-not-found
kubectl delete -f /tmp/k8s-deploy/k8s/namespace.yaml --ignore-not-found
```

- [ ] Ingress 삭제 후 관련 ALB 가 사라지거나 삭제 중  

### 6-2. LB Controller

```bash
helm uninstall aws-load-balancer-controller -n kube-system || true
kubectl -n kube-system delete sa aws-load-balancer-controller --ignore-not-found
```

### 6-3. Terraform destroy

```bash
cd terraform
# enable_eks=true 인 채로 destroy 하면 클러스터+네트워크 일괄 삭제
terraform destroy -auto-approve
```

또는 EKS만 끄기:

```hcl
enable_eks = false
```

```bash
terraform apply -auto-approve   # EKS/ECR/IAM 제거, 네트워크 유지 시
# 네트워크까지 끊으려면 destroy
```

### 6-4. 잔존 점검 (콘솔 또는 CLI)

```bash
aws eks list-clusters --region ap-northeast-2
aws ec2 describe-nat-gateways --region ap-northeast-2 \
  --filter Name=state,Values=available \
  --query 'NatGateways[].NatGatewayId' --output text
aws elbv2 describe-load-balancers --region ap-northeast-2 \
  --query 'LoadBalancers[].LoadBalancerArn' --output text
aws ecr describe-repositories --region ap-northeast-2 \
  --query 'repositories[?contains(repositoryName, `cloud-infra`)].repositoryName' --output text
```

- [ ] EKS 클러스터 없음 (또는 의도한 것만)  
- [ ] NAT available 없음  
- [ ] 데모용 ALB 없음  
- [ ] (선택) ECR 이미지는 스토리지 소액 — 필요 시 리포 삭제  

```bash
# ECR까지 지우려면 destroy 로 enable_eks 경로의 ecr 리소스 포함 삭제 권장
```

---

## 7. 타임라인 요약 (하루 데모)

| 순서 | 단계 | 대략 시간 | 과금 시작 |
|------|------|-----------|-----------|
| 0 | 도구·Compose 스모크 | 15~30분 | 없음 |
| 1 | TF apply (VPC+NAT+EKS) | 15~25분 | NAT·EKS·노드 |
| 2 | LB Controller | 5~10분 | — |
| 3 | ECR 푸시 | 5~15분 | ECR 소액 |
| 4 | k8s 배포 | 5~15분 | ALB |
| 5 | E2E curl·브라우저 | 10분 | — |
| 6 | destroy·잔존 점검 | 15~25분 | 과금 종료 |

**팁:** 단계 1 apply 직전에야 `enable_eks=true` 로 바꾸고, 단계 5 끝나자마자 단계 6으로.

---

## 8. 원라이너 치트시트 (환경 변수 재설정)

```bash
export AWS_REGION=ap-northeast-2
export CLUSTER_NAME=$(terraform -chdir=terraform output -raw eks_cluster_name)
export VPC_ID=$(terraform -chdir=terraform output -raw vpc_id)
export LB_ROLE_ARN=$(terraform -chdir=terraform output -raw aws_lb_controller_role_arn)
export ECR_FE=$(terraform -chdir=terraform output -json ecr_repository_urls | jq -r .fe)
export ECR_BE=$(terraform -chdir=terraform output -json ecr_repository_urls | jq -r .be)
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
export ALB_DNS=$(kubectl -n cloud-infra get ingress cloud-infra -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

---

## 9. 성공/실패 판정 (짧은 버전)

| 결과 | 조건 |
|------|------|
| **성공** | ALB 로 `/`, `/health`, `/api/hello` 200 + 노드 Ready + destroy 완료 |
| **부분 성공** | 클러스터·Pod 만 OK, Ingress 실패 → Controller/태그 이슈로 기록 |
| **실패 후 필수** | 어쨌든 **destroy / 잔존 ALB·NAT·EKS 점검** |

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| v1.0 | 2026-07-17 | 초판 — 권장 A E2E 명령 순서·비용 정리 |
