# syntax=docker/dockerfile:1
# 기본 타깃: linux/amd64 (EKS x86 노드). Mac 로컬도 buildx 로 amd64 빌드 권장.
#   docker build --platform linux/amd64 -t cloud-infra-be:local ./BE
ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM node:20-alpine

WORKDIR /app

ARG GIT_SHA=dev
ARG APP_VERSION=0.1.0
ENV GIT_SHA=$GIT_SHA \
    APP_VERSION=$APP_VERSION \
    NODE_ENV=production \
    PORT=3000 \
    SERVICE_NAME=cloud-infra-be

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src ./src

EXPOSE 3000
USER node

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]
