# Stage 1 Apply 런북

네트워크(VPC·서브넷 6·NAT 2·RT 5·SG 4)만 배포한다.  
**EKS는 기본 비활성** (`enable_eks = false`).

## 사전 조건

- Terraform ≥ 1.5, AWS CLI 자격증명
- `terraform/terraform.tfvars` 존재 (`my_ip` 설정)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# my_ip 수정
```

## 배포

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output deployment_summary
```

### 기대 결과 (요약)

| 리소스 | 개수 |
|--------|------|
| VPC / IGW | 1 / 1 |
| Subnet | 6 |
| NAT / EIP | 2 / 2 |
| Route Table | 5 |
| Security Group | 4 |
| EKS | 0 (기본) |

## 검증 체크

- [ ] Public 서브넷에 `kubernetes.io/role/elb=1` 태그
- [ ] Private Web에 `kubernetes.io/role/internal-elb=1` 태그
- [ ] Private Web AZ별 NAT 라우트
- [ ] Private DB에 `0.0.0.0/0` 없음

## 정리 (비용)

```bash
terraform destroy
# yes 확인
```

NAT·EIP는 시간 과금이므로 **작업 후 destroy** 권장.

## Bastion 켤 때 (Stage 2)

```hcl
enable_bastion   = true
bastion_key_name = "your-keypair"   # SSM 만 쓰면 ""
```

접속 방법: [BASTION.md](BASTION.md)

## EKS 켤 때 (Stage 4)

`terraform.tfvars`:

```hcl
enable_eks = true
# enable_ecr = true  # eks true 시 ECR도 같이 생성됨
```

이후 [EKS_DESIGN.md](EKS_DESIGN.md) 및 `k8s/README.md` 참고.
