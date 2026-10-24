#!/bin/sh
# Starts the website container: render the Caddyfile from the environment (it
# refuses wrong settings), check it, then hand the process over to Caddy so
# that SIGTERM from the orchestrator reaches it.
set -eu

CADDYFILE=/tmp/Caddyfile
bun /opt/front/web/front/render.ts > "$CADDYFILE"
caddy validate --config "$CADDYFILE" --adapter caddyfile > /dev/null
exec caddy run --config "$CADDYFILE" --adapter caddyfile
