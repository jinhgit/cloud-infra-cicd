# 기여 / 커밋 규칙

## 커밋 메시지

- **기본 언어: 한국어** (영문 기술 용어 병기 가능)
- 제목 한 줄 + 필요 시 본문
- 권장 prefix (선택):

| Prefix | 용도 |
|--------|------|
| `feat` | 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 |
| `chore` | 설정·가드·잡무 |
| `ci` | Actions |

예:

```text
feat(scripts): k8s 이미지 렌더·배포 스크립트 추가

- render-k8s-images.sh / deploy-k8s.sh
- E2E 시 sed 수동 작업 제거
```

## 과금

- 유료 AWS apply 는 사용자 확인 필수 — [AGENTS.md](AGENTS.md), [docs/FREE_MODE.md](docs/FREE_MODE.md)
- 일상: `./scripts/dev-free.sh`

## PR 전 로컬 체크

```bash
cd BE && npm test
./scripts/integration-test.sh   # Docker 필요
cd terraform && terraform fmt -check -recursive && terraform validate
```
