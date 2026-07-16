FROM node:20-alpine

WORKDIR /app

# 재현 가능한 설치 (lock 파일 사용)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src ./src

ENV NODE_ENV=production
ENV PORT=3000
ENV SERVICE_NAME=cloud-infra-be

EXPOSE 3000

USER node

# alpine 이미지에 wget 없을 수 있어 node 로 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "src/server.js"]
