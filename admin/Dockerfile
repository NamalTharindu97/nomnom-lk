# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

RUN npm install -g npm@latest && npm cache clean --force && rm -rf /tmp/*
COPY package.json package-lock.json ./
RUN npm install

COPY . .

ARG NEXT_PUBLIC_API_URL=/api/v1
ARG API_PROXY_TARGET=http://localhost:8080
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV API_PROXY_TARGET=$API_PROXY_TARGET
RUN npm run build

# Runtime stage
FROM node:22-alpine AS runtime

RUN npm install -g npm@latest && npm cache clean --force && rm -rf /tmp/*

WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.ts ./next.config.ts

EXPOSE 3000

CMD ["sh", "-c", "npx next start -p ${PORT:-3000}"]
