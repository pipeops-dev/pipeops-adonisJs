# Use BuildKit for better caching and performance
# syntax=docker/dockerfile:1.4

# Base stage
FROM node:20.12.2-alpine3.18 as base

# All deps stage
FROM base as deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Production-only deps stage
FROM base as production-deps
WORKDIR /app
COPY package.json package-lock.json .env ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Install pino-pretty
RUN --mount=type=cache,target=/root/.npm \
    npm install pino-pretty

# Build stage
FROM base as build
WORKDIR /app
COPY --from=deps /app/node_modules /app/node_modules
COPY . .
RUN node ace build

# Production stage
FROM base
ARG PORT
ENV TZ=UTC \
    HOST=0.0.0.0 \
    LOG_LEVEL=info \
    APP_KEY=KsSHcSwIiCsxg2jQvoF7DPsnqzpnfiVd \
    NODE_ENV=production \
    DB_HOST=127.0.0.1 \
    DB_PORT=5432 \
    DB_USER=postgres \
    DB_DATABASE=pipeops \
    PORT=$PORT
WORKDIR /app
COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/build /app
EXPOSE 8080
CMD ["node", "./bin/server.js"]
