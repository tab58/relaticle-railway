#!/bin/sh
# Swap the __REVERB_*__ placeholders baked into the Vite bundle for the real
# runtime env. Idempotent: a second run finds no placeholders and changes nothing.
# ponytail: sed on a built asset. Proper fix is upstream reading Reverb config
# from a <meta> tag at runtime; drop this script when that ships.
set -eu

for f in /var/www/html/public/build/assets/echo-*.js; do
    [ -f "$f" ] || continue
    grep -Eq '__REVERB_[A-Z_]+__' "$f" || continue
    sed -i \
        -e "s|__REVERB_APP_KEY__|${REVERB_APP_KEY:-}|g" \
        -e "s|__REVERB_HOST__|${REVERB_HOST:-}|g" \
        -e "s|__REVERB_PORT__|${REVERB_PORT:-443}|g" \
        -e "s|__REVERB_SCHEME__|${REVERB_SCHEME:-https}|g" \
        "$f"
    echo "👉 [NOTICE]: Reverb client config injected into $(basename "$f")"
done
