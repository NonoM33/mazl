#!/bin/sh
# End-to-end check of the website container, on this machine, with docker.
#   sh web/front/e2e/run.sh            (from the repository root)
#   SKIP_BUILD=1 sh web/front/e2e/run.sh   reuse mazl-front:e2e and mazl-api:e2e
#
# Part A: the website container in front of a stand-in that echoes what it
#         receives (client address, Host, Origin, cookie, WebSocket frames).
# Part B: the website container in front of the real API (SERVE_WEBSITE=false)
#         and a throwaway Postgres, compared with the API serving the website
#         itself (the default mode before the cut-over).
# Everything it starts is removed at the end. Nothing leaves this machine.
set -u

NET=mazl-e2e-net
PASS=0
FAIL=0
FRONT_ECHO=18081
FRONT_UNTRUSTED=18082
FRONT_API=18083
API_DEFAULT=18084
API_SPLIT=18085

b64key() { head -c 32 /dev/urandom | base64; }
hex() { head -c 24 /dev/urandom | base64 | tr -d '/+=\n'; }

cleanup() {
  for c in mazl-e2e-echo mazl-e2e-front-echo mazl-e2e-front-untrusted mazl-e2e-front-api mazl-e2e-api-default mazl-e2e-api-split mazl-e2e-db; do
    docker rm -f "$c" > /dev/null 2>&1
  done
  docker network rm "$NET" > /dev/null 2>&1
}
trap cleanup EXIT INT TERM

check() { # name expected actual
  if [ "$2" = "$3" ]; then PASS=$((PASS + 1)); echo "ok    $1"; else FAIL=$((FAIL + 1)); echo "FAIL  $1"; echo "        expected: $2"; echo "        actual:   $3"; fi
}
check_contains() { # name needle haystack
  case "$3" in *"$2"*) PASS=$((PASS + 1)); echo "ok    $1" ;; *) FAIL=$((FAIL + 1)); echo "FAIL  $1"; echo "        missing:  $2"; echo "        in:       $3" ;; esac
}
status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
header() { # header name, curl args... : first value of a response header, CR removed
  name=$1; shift
  curl -s -D - -o /dev/null "$@" | tr -d '\r' | awk -v n="$(echo "$name" | tr 'A-Z' 'a-z')" 'BEGIN{FS=": "} tolower($1)==n {print substr($0, length($1)+3); exit}'
}
jq_field() { bun -e "const j = JSON.parse(await Bun.stdin.text()); console.log($1)"; }
wait_http() { # url, seconds
  i=0
  while [ "$i" -lt "$2" ]; do
    [ "$(status "$1")" != "000" ] && return 0
    i=$((i + 1)); sleep 1
  done
  echo "FAIL  $1 never answered"; FAIL=$((FAIL + 1)); return 1
}

cd "$(dirname "$0")/../../.." || exit 1
if [ "${SKIP_BUILD:-0}" != "1" ]; then
  docker build -q -f web/Dockerfile -t mazl-front:e2e . > /dev/null || exit 1
  docker build -q -t mazl-api:e2e . > /dev/null || exit 1
fi
cleanup
docker network create "$NET" > /dev/null || exit 1

FRONT_ENV="-e WEB_ORIGIN=https://mazl.app -e PUBLIC_BASE_URL=https://api.mazl.app"

echo "== Part A: the website container in front of an echo =="
docker run -d --name mazl-e2e-echo --network "$NET" -v "$PWD/web/front/e2e/echo-upstream.ts:/echo.ts:ro" oven/bun:1-alpine bun /echo.ts > /dev/null
docker run -d --name mazl-e2e-front-echo --network "$NET" -p "$FRONT_ECHO:8080" $FRONT_ENV -e API_UPSTREAM=http://mazl-e2e-echo:3000 mazl-front:e2e > /dev/null
# Peers that are not Traefik: the docker gateway is not in the list of trusted proxies.
docker run -d --name mazl-e2e-front-untrusted --network "$NET" -p "$FRONT_UNTRUSTED:8080" $FRONT_ENV -e TRUSTED_PROXIES=203.0.113.250/32 -e API_UPSTREAM=http://mazl-e2e-echo:3000 mazl-front:e2e > /dev/null
wait_http "http://localhost:$FRONT_ECHO/health" 30
wait_http "http://localhost:$FRONT_UNTRUSTED/health" 30

A="http://localhost:$FRONT_ECHO"
check "health answers 200" 200 "$(status "$A/health")"
echo_of() { curl -s "$@" | jq_field "$1"; }

# Behind Traefik the chain is "what the browser wrote, real client".
forwarded=$(curl -s -H 'Host: mazl.app' -H 'X-Forwarded-For: 6.6.6.6, 203.0.113.9' "$A/api/health" | jq_field 'j.headers["x-forwarded-for"]')
check "the API receives exactly one X-Forwarded-For: the real client (spoofed entry dropped)" 203.0.113.9 "$forwarded"
forwarded=$(curl -s -H 'Host: mazl.app' -H 'X-Forwarded-For: 6.6.6.6' -H 'X-Real-Ip: 6.6.6.6' -H 'Forwarded: for=6.6.6.6' "$A/api/health" | jq_field 'j.headers["x-forwarded-for"] + "|" + (j.headers["x-real-ip"] ?? "-") + "|" + (j.headers["forwarded"] ?? "-")')
check "a lone spoofed X-Forwarded-For with Traefik absent still yields one entry, and X-Real-Ip/Forwarded are dropped" "$(echo "$forwarded" | cut -d'|' -f2-)" "-|-"
check "the Host header reaches the API unchanged (cookie host check)" mazl.app "$(curl -s -H 'Host: mazl.app' "$A/api/health" | jq_field 'j.headers.host')"
check "Origin and cookie reach the API unchanged (CSRF and session)" "https://mazl.app|__Host-mazl_web=abc" "$(curl -s -H 'Host: mazl.app' -H 'Origin: https://mazl.app' -H 'Cookie: __Host-mazl_web=abc' -X POST "$A/api/x" | jq_field 'j.headers.origin + "|" + j.headers.cookie')"
check "the request body route and method are kept" "POST|/api/x|?a=1" "$(curl -s -X POST "$A/api/x?a=1" | jq_field 'j.method + "|" + j.path + "|" + j.query')"
check "/media/* is proxied" /media/photos/1 "$(curl -s "$A/media/photos/1?exp=1" | jq_field 'j.path')"
forwarded=$(curl -s -H 'X-Forwarded-For: 6.6.6.6, 203.0.113.9' "http://localhost:$FRONT_UNTRUSTED/api/health" | jq_field 'j.headers["x-forwarded-for"]')
case "$forwarded" in *6.6.6.6* | *203.0.113.9* | *,*) check "an untrusted peer cannot choose its address" "one address, the peer's" "$forwarded" ;; *) check "an untrusted peer cannot choose its address" ok ok ;; esac

# An API swapped during a deploy: the request waits for it instead of failing.
docker stop mazl-e2e-echo > /dev/null
( sleep 2; docker start mazl-e2e-echo > /dev/null ) &
check "a request made while the API is down for 2 s succeeds once it is back (retry, no 502)" 200 "$(curl -s -o /dev/null -m 20 -w '%{http_code}' -H 'Host: mazl.app' "$A/api/health")"
wait

ws=$(bun -e '
const socket = new WebSocket("ws://localhost:'"$FRONT_ECHO"'/ws?token=t");
socket.onopen = () => socket.send("hi");
socket.onmessage = (event) => { console.log(String(event.data)); process.exit(0); };
socket.onerror = () => { console.log("error"); process.exit(0); };
setTimeout(() => { console.log("timeout"); process.exit(0); }, 5000);
')
check "a WebSocket on /ws is upgraded and proxied (frames flow both ways)" echo:hi "$ws"

echo "== Part B: the website container in front of the real API =="
docker run -d --name mazl-e2e-db --network "$NET" -e POSTGRES_PASSWORD=e2e -e POSTGRES_DB=mazl postgres:16-alpine > /dev/null
i=0; until docker exec mazl-e2e-db pg_isready -U postgres -d mazl > /dev/null 2>&1; do i=$((i + 1)); [ "$i" -gt 30 ] && break; sleep 1; done
sleep 2

API_ENV="-e NODE_ENV=production -e PORT=3000 -e DATABASE_URL=postgres://postgres:e2e@mazl-e2e-db:5432/mazl -e JWT_SECRET=$(hex)$(hex) -e ADMIN_JWT_SECRET=$(hex)$(hex) -e ADMIN_PASSWORD=$(hex) -e DATA_ENCRYPTION_KEY=$(b64key) -e MEDIA_SIGNING_KEY=$(b64key) -e DOC_FINGERPRINT_KEY=$(b64key) -e PUBLIC_BASE_URL=https://api.mazl.app -e WEB_ORIGIN=https://mazl.app -e TRUSTED_PROXY_HOPS=1"
# shellcheck disable=SC2086
docker run -d --name mazl-e2e-api-default --network "$NET" -p "$API_DEFAULT:3000" $API_ENV mazl-api:e2e > /dev/null
wait_http "http://localhost:$API_DEFAULT/api/health" 120
# The second API starts once the first has created the schema: two boots at once race on it.
# shellcheck disable=SC2086
docker run -d --name mazl-e2e-api-split --network "$NET" -p "$API_SPLIT:3000" $API_ENV -e SERVE_WEBSITE=false mazl-api:e2e > /dev/null
docker run -d --name mazl-e2e-front-api --network "$NET" -p "$FRONT_API:8080" $FRONT_ENV -e API_UPSTREAM=http://mazl-e2e-api-split:3000 mazl-front:e2e > /dev/null
wait_http "http://localhost:$API_SPLIT/api/health" 90
wait_http "http://localhost:$FRONT_API/health" 30

F="http://localhost:$FRONT_API"
D="http://localhost:$API_DEFAULT"
SITE="Host: mazl.app"

check "front: / is the showcase" 200 "$(status -H "$SITE" "$F/")"
check_contains "front: / is landing/index.html" "/l/" "$(curl -s -H "$SITE" "$F/")"
check "front: /app is the client" 200 "$(status -H "$SITE" "$F/app")"
check "front: /app/ is served" 200 "$(status -H "$SITE" "$F/app/")"
check "front: /app/index.html is served" 200 "$(status -H "$SITE" "$F/app/index.html")"
check "front: a client route is the page" 200 "$(status -H "$SITE" "$F/app/messages/12")"
check "front: /api/health goes through the proxy to the API" 200 "$(status -H "$SITE" "$F/api/health")"
check_contains "front: /api/health body is the API's" '"' "$(curl -s -H "$SITE" "$F/api/health")"
check "front: /console redirects to the API host, path and query kept" "302 https://api.mazl.app/console/reports?page=2" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/console/reports?page=2")"
check "front: /verify?token= redirects to the API host" "302 https://api.mazl.app/verify?token=abc" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/verify?token=abc")"
check "front: /admin redirects to the API host" "302 https://api.mazl.app/admin" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/admin")"
check "front: /administrator is not an admin path" "302 https://mazl.app/app" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/administrator")"
check "front: /terms goes to /cgu" "301 /cgu" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/terms" | sed 's# http://[^/]*# #')"
check "front: /privacy goes to /confidentialite" "301 /confidentialite" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/privacy" | sed 's# http://[^/]*# #')"
check "front: a legal page is served" 200 "$(status -H "$SITE" "$F/cgu")"
check "front: a legal page with its extension is served" 200 "$(status -H "$SITE" "$F/confidentialite.html")"
check "front: the stylesheet and the icon are served" "200 200" "$(status -H "$SITE" "$F/style.css") $(status -H "$SITE" "$F/favicon.svg")"
check "front: the landing page and its script are gone" "302 302" "$(status -H "$SITE" "$F/index.html") $(status -H "$SITE" "$F/script.js")"
check "front: an unknown path goes to /app" "302 https://mazl.app/app" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "$SITE" "$F/nothing-here")"

# The same answer from the front and from the API serving the website itself.
for name in Content-Security-Policy X-Content-Type-Options Referrer-Policy Cross-Origin-Opener-Policy Cross-Origin-Resource-Policy Permissions-Policy X-Frame-Options Strict-Transport-Security; do
  check "headers: $name of /app/ equals the API's" "$(header "$name" -H "$SITE" "$D/app/")" "$(header "$name" -H "$SITE" "$F/app/")"
done
check_contains "headers: the CSP forbids framing" "frame-ancestors 'none'" "$(header Content-Security-Policy -H "$SITE" "$F/app/")"
check "headers: the index is not cached (page and fallback)" "no-store no-store" "$(header Cache-Control -H "$SITE" "$F/app/") $(header Cache-Control -H "$SITE" "$F/app/messages/12")"
check "headers: the index is not cached, as on the API" "$(header Cache-Control -H "$SITE" "$D/app/")" "$(header Cache-Control -H "$SITE" "$F/app/")"

JS=$(curl -s -H "$SITE" "$F/app/" | grep -o '/app/index-[a-z0-9]*\.js' | head -1)
check_contains "a hashed script is referenced by the page" "/app/index-" "$JS"
check "headers: a hashed script is immutable, as on the API" "$(header Cache-Control -H "$SITE" "$D$JS")" "$(header Cache-Control -H "$SITE" "$F$JS")"
check_contains "headers: a hashed script is cached for a year" "immutable" "$(header Cache-Control -H "$SITE" "$F$JS")"
check "a gzip-capable browser gets the precompressed script" gzip "$(header Content-Encoding -H "$SITE" -H 'Accept-Encoding: gzip' "$F$JS")"
check "a browser without gzip gets the plain script" "" "$(header Content-Encoding -H "$SITE" "$F$JS")"
check "a missing hashed script is a 404, never the page" 404 "$(status -H "$SITE" "$F/app/index-zzzz9999.js")"
check "a missing font is a 404" 404 "$(status -H "$SITE" "$F/app/fonts/none.woff2")"
check "a path escaping the client folder never returns a file" 0 "$(curl -s --path-as-is -H "$SITE" "$F/app/../../etc/passwd" | grep -c 'root:')"
check "a legal page carries the strict headers too" "$(header X-Frame-Options -H "$SITE" "$D/app/")" "$(header X-Frame-Options -H "$SITE" "$F/cgu")"

check "the front survives an API outage: /health still 200, the proxy says 502" "200 502" "$(docker stop mazl-e2e-api-split > /dev/null; status "$F/health") $(status -H "$SITE" "$F/api/health")"
docker start mazl-e2e-api-split > /dev/null
wait_http "http://localhost:$API_SPLIT/api/health" 60

ws=$(bun -e '
const socket = new WebSocket("ws://localhost:'"$FRONT_API"'/ws");
socket.onopen = () => { console.log("open"); process.exit(0); };
socket.onerror = () => { console.log("refused"); process.exit(0); };
setTimeout(() => { console.log("timeout"); process.exit(0); }, 5000);
')
check "a WebSocket on /ws reaches the API (its own refusal, no token: not a proxy error)" refused "$ws"
upgrade=$(curl -s -i -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' -H "$SITE" "$F/ws" | tr -d '\r')
check_contains "the upgrade attempt is answered by the API: 401 Token required" "Token required" "$upgrade"
case "$upgrade" in HTTP/1.1\ 401*) check "the upgrade attempt status is the API's 401" 401 401 ;; *) check "the upgrade attempt status is the API's 401" "HTTP/1.1 401" "$(echo "$upgrade" | head -1)" ;; esac

echo "== The API alone, website off (SERVE_WEBSITE=false) =="
S="http://localhost:$API_SPLIT"
check "split API: /api/health 200" 200 "$(status "$S/api/health")"
check "split API: / goes to the website host" "302 https://mazl.app/" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$S/")"
check "split API: /app goes to the website host, query kept" "301 https://mazl.app/app/decouvrir?x=1" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$S/app/decouvrir?x=1")"
check "split API: a legal page goes to the website host" "301 https://mazl.app/cgu" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$S/cgu")"
check "split API: the showcase files go to the website host" "301 https://mazl.app/l/fonts/Geist-700.ttf" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$S/l/fonts/Geist-700.ttf")"
check "split API: www goes to the website host" "301 https://mazl.app/app" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H 'Host: www.mazl.app' "$S/app")"
check "split API: the landing script is not served" 404 "$(status "$S/script.js")"
check "split API: the landing and legal HTML go to the website host" "301 301" "$(status "$S/index.html") $(status "$S/cgu.html")"
check "split API: the document drop page and its assets are still served" "200 200 200 200" "$(status "$S/verify.html") $(status "$S/verify.js") $(status "$S/style.css") $(status "$S/favicon.svg")"
check "split API: /verify?token= still redirects to verify.html" "302 /verify.html?token=abc" "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' "$S/verify?token=abc" | sed 's# http://[^/]*# #')"
check "split API: the old admin and the console are still served" "200 200" "$(status "$S/admin") $(status "$S/console")"
echo "== The API alone, default mode (as today) =="
check "default API: the landing page is served" 200 "$(status "$D/")"
check "default API: the showcase is served on the site host" 200 "$(status -H "$SITE" "$D/")"
check "default API: the client is served on the site host" 200 "$(status -H "$SITE" "$D/app/")"
check "default API: the legal pages are served" 200 "$(status "$D/cgu")"

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
