# BE — Backend

Node.js 20 + Express REST API. EKS / Docker 공용.

## API

| Method | Path | 설명 |
|--------|------|------|
| GET | `/health` | 헬스체크 (K8s·ALB·Docker) |
| GET | `/api` | 엔드포인트 목록 |
| GET | `/api/hello` | 샘플 응답 |
| GET | `/api/info` | 런타임 메타 (uptime 등) |

## 로컬 실행

```bash
cd BE
cp .env.example .env   # 선택
npm ci
npm run dev            # http://localhost:3000/health
npm test
```

## Docker

```bash
cd BE
docker build -t cloud-infra-be .
docker run --rm -p 3000:3000 cloud-infra-be
curl -s http://localhost:3000/health | jq .
```

통합 실행은 저장소 루트 `docker compose up --build`.

## 환경 변수

| 변수 | 기본 | 설명 |
|------|------|------|
| `PORT` | `3000` | 리스닝 포트 |
| `NODE_ENV` | `development` / 이미지 `production` | 환경 |
| `SERVICE_NAME` | `cloud-infra-be` | 응답 식별자 |
