FROM node:20.12.2-alpine3.18 as base

# All deps stage
FROM base as deps
WORKDIR /app
ADD package.json package-lock.json ./
RUN npm ci

# Production only deps stage
FROM base as production-deps
WORKDIR /app
ADD package.json package-lock.json .env ./
RUN npm ci --omit=dev

# Install pino-pretty
RUN npm install pino-pretty

# Build stage
FROM base as build
WORKDIR /app
COPY --from=deps /app/node_modules /app/node_modules
ADD . .
RUN node ace build

# Production stage
FROM base
ARG PORT
ENV TZ=UTC
ENV HOST=0.0.0.0
ENV LOG_LEVEL=info
ENV APP_KEY=KsSHcSwIiCsxg2jQvoF7DPsnqzpnfiVd
ENV NODE_ENV=production
ENV DB_HOST=127.0.0.1
ENV DB_PORT=5432
ENV DB_USER=postgres
ENV DB_DATABASE=pipeops
ENV PORT $PORT
WORKDIR /app
COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/build /app
EXPOSE 8080
CMD ["node", "./bin/server.js"]
