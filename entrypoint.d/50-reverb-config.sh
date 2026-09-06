#!/bin/sh
# Swap the __REVERB_*__ placeholders baked into the Vite bundle for the real
# runtime env, then rename the chunk after its new content so CDN caches
# (Cloudflare honours the 1y immutable header) can't serve a stale key.
# Idempotent: a second run finds no placeholders and changes nothing.
# ponytail: sed on a built asset. Proper fix is upstream reading Reverb config
# from a <meta> tag at runtime; drop this script when that ships.
set -eu

build=/var/www/html/public/build
for f in "$build"/assets/echo-*.js; do
    [ -f "$f" ] || continue
    grep -Eq '__REVERB_[A-Z_]+__' "$f" || continue
    sed -i \
        -e "s|__REVERB_APP_KEY__|${REVERB_APP_KEY:-}|g" \
        -e "s|__REVERB_HOST__|${REVERB_HOST:-}|g" \
        -e "s|__REVERB_PORT__|${REVERB_PORT:-443}|g" \
        -e "s|__REVERB_SCHEME__|${REVERB_SCHEME:-https}|g" \
        "$f"
    old=$(basename "$f")
    new="echo-$(sha1sum "$f" | cut -c1-8).js"
    mv "$f" "$build/assets/$new"
    sed -i "s|$old|$new|g" "$build/manifest.json"
    echo "👉 [NOTICE]: Reverb client config injected into $new"
done
