FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lock* ./
RUN bun install --production --frozen-lockfile

# Build stage
FROM base AS runner
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# OpenJPEG decodes the JPEG 2000 face photo stored in passport chips (DG2).
RUN apt-get update \
 && apt-get install -y --no-install-recommends libopenjp2-tools ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Face models (OpenCV Zoo), checksums pinned in the script.
RUN bun scripts/fetch-face-models.ts

# Uploads stored locally (Coolify volume recommended)
RUN mkdir -p /app/uploads

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Run as the non-root user shipped in the oven/bun image, and give it
# ownership of the app directory (including the uploads volume mount point).
RUN chown -R bun:bun /app
VOLUME ["/app/uploads"]
USER bun

# Verify the app answers on its health endpoint using bun (no extra packages).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD ["bun", "-e", "const r = await fetch('http://127.0.0.1:' + (process.env.PORT ?? '3000') + '/api/health'); process.exit(r.ok ? 0 : 1);"]

CMD ["bun", "src/index.ts"]
