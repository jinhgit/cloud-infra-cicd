# FE — Frontend

정적 HTML/CSS/JS + Nginx. **same-origin API** (`/health`, `/api/*`) 를 기본으로 한다.

## 실행 방법

### 1) Docker Compose (권장 — FE+BE 통합)

```bash
# 저장소 루트
docker compose up --build
# http://localhost:8080  → /health, /api/hello 프록시됨
```

### 2) FE 이미지만

```bash
cd FE
docker build -t cloud-infra-fe .
# BE 가 docker 네트워크 이름 be 로 떠 있어야 /api 프록시 동작
docker run --rm -p 8080:80 --network container:cloud-infra-be cloud-infra-fe
# 또는 compose 사용 권장
```

### 3) 정적 서버만 (프록시 없음)

```bash
# BE 를 먼저 :3000 에 실행한 뒤
# public/js/config.js 의 API_BASE_URL 을 "http://localhost:3000" 으로 변경
python3 -m http.server 8080 --directory public
```

## 설정

| 모드 | `API_BASE_URL` | 비고 |
|------|----------------|------|
| Compose / EKS Ingress | `""` (기본) | same-origin |
| FE-only static | `http://localhost:3000` | CORS 허용됨 (BE) |

## 헬스

- FE: `GET /healthz` → `ok`
- BE (프록시): `GET /health` → JSON
