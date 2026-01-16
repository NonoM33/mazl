FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lock* ./
RUN bun install --production

# Build stage
FROM base AS runner
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Uploads stored locally (Coolify volume recommended)
RUN mkdir -p /app/uploads
VOLUME ["/app/uploads"]

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Healthcheck to verify app is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["bun", "src/index.ts"]
