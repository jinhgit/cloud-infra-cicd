# BE — Backend

포트폴리오용 REST API. **EKS Deployment** 로 배포하고 `/health` 로 헬스체크한다.

## 요구 사항

- Node.js 20+

## 로컬 실행

```bash
cd BE
cp .env.example .env
npm install
npm run dev
# http://localhost:3000/health
```

Docker:

```bash
docker build -t cloud-infra-be .
docker run --rm -p 3000:3000 cloud-infra-be
```

## 디렉터리

```
BE/
├── src/
│   ├── server.js         # 엔트리
│   ├── app.js            # Express 앱
│   ├── config/           # 환경 설정
│   ├── routes/           # 라우트
│   └── middleware/       # 미들웨어
├── tests/
├── package.json
├── Dockerfile
├── .env.example
└── README.md
```

## API

| Method | Path | 설명 |
|--------|------|------|
| GET | `/health` | 헬스체크 (K8s/ALB) |
| GET | `/api` | API 메타 |
| GET | `/api/hello` | 샘플 응답 |

## 환경 변수

| 변수 | 기본 | 설명 |
|------|------|------|
| `PORT` | `3000` | 리스닝 포트 |
| `NODE_ENV` | `development` | 환경 |
