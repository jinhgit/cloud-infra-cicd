// API 베이스 URL
// - "" (권장): same-origin → /health, /api/*
//   · Docker Compose: Nginx 가 be:3000 으로 프록시
//   · EKS Ingress: ALB 가 경로별로 FE/BE 라우팅
// - "http://localhost:3000": python -m http.server 등 프록시 없이 FE만 띄울 때
window.APP_CONFIG = {
  API_BASE_URL: "",
};
