#!/bin/sh
# Builds the image and proves the boot-time Reverb substitution works.
# Fails if a __REVERB_*__ placeholder survives or the proxy patch is missing.
set -eu
IMG=${IMG:-relaticle-railway:test}
docker build --platform linux/amd64 -q -t "$IMG" . >/dev/null

out=$(docker run --rm --platform linux/amd64 \
    -e REVERB_APP_KEY=testkey123 -e REVERB_HOST=ws.example.test -e REVERB_PORT=443 -e REVERB_SCHEME=https \
    --entrypoint sh "$IMG" -c '
        /etc/entrypoint.d/50-reverb-config.sh >/dev/null
        /etc/entrypoint.d/50-reverb-config.sh >/dev/null   # idempotent
        cat /var/www/html/public/build/assets/echo-*.js
        echo; grep -c "100.64.0.0/10" /var/www/html/bootstrap/app.php
        ls /var/www/html/public/build/assets/echo-*.js | wc -l')

echo "$out" | grep -q '`testkey123`'                || { echo "FAIL: key not substituted"; exit 1; }
echo "$out" | grep -q '`ws.example.test`'           || { echo "FAIL: host not substituted"; exit 1; }
echo "$out" | grep -q 'wssPort:`443`'               || { echo "FAIL: port not substituted"; exit 1; }
echo "$out" | grep -q '`https`'                     || { echo "FAIL: scheme not substituted"; exit 1; }
echo "$out" | grep -q 'forceTLS:!1'                 && { echo "FAIL: forceTLS folded to false at build"; exit 1; }
echo "$out" | grep -Eq '__REVERB_[A-Z_]+__'                  && { echo "FAIL: placeholder survived"; exit 1; }
echo "$out" | tail -2 | head -1 | grep -qx 1        || { echo "FAIL: proxy patch missing"; exit 1; }
echo "$out" | tail -1 | grep -qx 1                  || { echo "FAIL: stale echo asset present"; exit 1; }
echo "PASS"
