# Bastion Host 가이드 (Stage 2)

Public 서브넷에 점프 서버를 두고, **개발자 IP(`my_ip`)에서만 SSH** 또는 **SSM Session Manager**로 접속합니다.

| 항목 | 값 |
|------|-----|
| 플래그 | `enable_bastion = true` |
| 배치 | Public 서브넷 AZ-A (`aws_subnet.public[0]`) |
| AMI | Amazon Linux 2023 (x86_64) |
| 기본 타입 | `t3.micro` |
| 루트 볼륨 | **30 GiB** gp3 (AL2023 AMI 최소 크기) |
| SG | 기존 `aws_security_group.bastion` (22 ← `my_ip`) |
| 추가 | SSM IAM (`AmazonSSMManagedInstanceCore`), Web SG에 Bastion→22 규칙 |

## 1. 사전 준비

```bash
# 공인 IP → terraform.tfvars my_ip
curl -s https://checkip.amazonaws.com

# (SSH 사용 시) 키 페어 생성 예
aws ec2 create-key-pair \
  --region ap-northeast-2 \
  --key-name cloud-infra-bastion \
  --query 'KeyMaterial' --output text > cloud-infra-bastion.pem
chmod 400 cloud-infra-bastion.pem
```

`terraform.tfvars` 예:

```hcl
my_ip            = "x.x.x.x/32"
enable_bastion   = true
bastion_key_name = "cloud-infra-bastion"   # SSM 만 쓰면 ""
enable_eks       = false
```

네트워크(VPC 등)가 아직 없으면 Bastion 과 함께 생성됩니다.

## 2. 배포

```bash
cd terraform
terraform plan -out=tfplan
terraform apply tfplan

terraform output bastion_public_ip
terraform output bastion_ssh_command
terraform output bastion_ssm_command
```

## 3. 접속

### SSH

```bash
ssh -i cloud-infra-bastion.pem ec2-user@<bastion_public_ip>
```

- 실패 시: 보안 그룹 `my_ip` 와 현재 공인 IP 일치 여부, 키 이름·권한(`400`) 확인.

### SSM Session Manager (키 불필요)

인스턴스 프로파일에 SSM 권한이 붙어 있고, 인스턴스가 **Public + IGW** 로 SSM 엔드포인트에 닿으면 됩니다 (또는 VPC 엔드포인트 — 본 구성은 Public 으로 충분).

```bash
# Session Manager 플러그인 필요:
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

aws ssm start-session \
  --target "$(terraform output -raw bastion_instance_id)" \
  --region ap-northeast-2
```

상태 확인:

```bash
aws ssm describe-instance-information --region ap-northeast-2 \
  --filters "Key=InstanceIds,Values=$(terraform output -raw bastion_instance_id)"
```

`PingStatus` 가 `Online` 이 될 때까지 1~2분 걸릴 수 있습니다.

## 4. 정리

```bash
# Bastion 만 끄기
# terraform.tfvars: enable_bastion = false
terraform apply

# 또는 전체 삭제
terraform destroy
```

## 보안 메모

- SSH 소스: **반드시 `my_ip/32`** (`0.0.0.0/0` 금지)
- IMDSv2 강제 (`http_tokens = required`)
- 루트 볼륨 암호화
- Private 워크로드 점프: Web SG 에 Bastion→22 규칙이 추가됨 (레거시 EC2용). EKS 노드 접속은 별도 보안 그룹/SSM 설계.

## Terraform 리소스

| 리소스 | 파일 |
|--------|------|
| `aws_instance.bastion` | `bastion.tf` |
| `aws_iam_role.bastion` + profile + SSM attach | `bastion.tf` |
| `aws_vpc_security_group_ingress_rule.web_ssh_from_bastion` | `bastion.tf` |
| SG 본체 | `security_groups.tf` |
