# FE — Frontend

포트폴리오용 프론트엔드. 최종적으로 **EKS + Nginx(또는 정적 서버)** 컨테이너로 배포한다.

## 로컬 실행

```bash
# 정적 파일만 확인 (Python)
cd FE
python3 -m http.server 8080 --directory public
# http://localhost:8080
```

또는 Docker:

```bash
docker build -t cloud-infra-fe .
docker run --rm -p 8080:80 cloud-infra-fe
```

## 디렉터리

```
FE/
├── public/           # 정적 에셋 (Nginx document root)
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── assets/
├── nginx.conf        # 컨테이너 Nginx 설정
├── Dockerfile
├── .dockerignore
└── README.md
```

## 백엔드 연동

- API base URL은 `public/js/config.js`의 `API_BASE_URL` 사용
- 로컬 기본: `http://localhost:3000`
- 클러스터에서는 Ingress/Service DNS로 교체

## 헬스

Nginx `/` 및 (프록시 시) `/api/health` — 백엔드 헬스와 분리
