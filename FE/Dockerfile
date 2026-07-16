# syntax=docker/dockerfile:1
# EKS 노드(x86) 호환: docker build --platform linux/amd64 -t cloud-infra-fe:local ./FE
ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
