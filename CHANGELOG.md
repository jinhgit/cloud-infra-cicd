# Changelog

형식: [Keep a Changelog](https://keepachangelog.com/) 느낌의 요약.  
커밋 메시지는 한국어 기본 ([CONTRIBUTING.md](CONTRIBUTING.md)).

## [Unreleased]

### Added
- P1/P2: 이미지 빌드·k8s 렌더/배포 스크립트, Docker amd64 CI, 통합 테스트
- BE `/api/info` 버전·gitSha 표시, FE 홈 연동
- lab.html 무료/유료 모드 안내
- Terraform PR plan 코멘트, OIDC 옵션 문서
- 비용 가드 `confirm_paid_apply` 이중 확인

## [0.3.x] — 2026-07

### Added
- EKS E2E 실전 (ALB 200), Bastion SSH/SSM
- FREE_MODE, dev-free, verify-lab, lab.html
- GitHub Actions: BE test, Terraform fmt/validate/plan

### Fixed
- EKS 1.32, 노드 t3.small (Free Tier), linux/amd64 이미지
- LB Controller IAM v2.13
- Bastion AL2023 루트 볼륨 30GiB

## [0.2.0] — 2026-07

- PRD v1.1 EKS 권장 A, FE/BE 스캐폴드, HA 네트워크 Terraform

## [0.1.0] — 2026-06

- 초기 Terraform 네트워크 구조
