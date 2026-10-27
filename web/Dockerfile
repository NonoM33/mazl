# The website container (mazl.app): the built web client, the legal pages and a
# reverse proxy to the API, served by Caddy. Independent of the API image
# (docs/deploy/README.md, docs/web/adr/W01-hebergement.md).
#
# Build from the repository root:
#   docker build -f web/Dockerfile -t mazl-front .
# Coolify: base directory "/", Dockerfile location "/web/Dockerfile", port 8080.

# Caddy, version and digest pinned (2.10.2). Only the static binary is used.
FROM caddy:2.10.2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d AS caddy

# The web client bundle and the showcase, hashed file names (web/build.ts, landing/build.ts). Scripts stay off:
# nothing here needs a postinstall, and the API's native modules are not built.
FROM oven/bun:1-alpine AS client
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --production --frozen-lockfile --ignore-scripts
COPY web/index.html web/build.ts web/tsconfig.json ./web/
COPY web/src ./web/src
COPY web/assets ./web/assets
RUN bun web/build.ts
# The showcase served at the root of the site (landing/build.ts: index.html + /l/ files).
COPY landing/index.html landing/build.ts landing/config.ts landing/tsconfig.json ./landing/
COPY landing/src ./landing/src
COPY landing/assets ./landing/assets
RUN bun landing/build.ts

FROM oven/bun:1-alpine
# No access log is configured (web/front/caddyfile.ts): query strings carry one-time tokens.
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=client /app/web/dist /srv/app
COPY --from=client /app/landing/dist /srv/landing
COPY public/cgu.html public/cgv.html public/confidentialite.html public/mentions-legales.html public/cookies.html public/style.css public/legal.css public/favicon.svg /srv/site/
# The Caddyfile is rendered at start from the very modules the API serves the
# website with, so headers, cache rules and host rules cannot drift.
COPY web/front /opt/front/web/front
COPY src/features/web-app/cache-rules.ts src/features/web-app/security-headers.ts src/features/web-app/site-rules.ts /opt/front/src/features/web-app/
RUN chmod 0555 /opt/front/web/front/entrypoint.sh

ENV PORT=8080 \
    XDG_CONFIG_HOME=/tmp/caddy/config \
    XDG_DATA_HOME=/tmp/caddy/data
EXPOSE 8080

USER bun
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${PORT}/health" || exit 1

ENTRYPOINT ["/opt/front/web/front/entrypoint.sh"]
