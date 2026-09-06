# Relaticle for Railway (and any host that terminates TLS at a proxy).
# Wraps the upstream image with two fixes:
#  1. Reverb client config at runtime. Vite inlines VITE_REVERB_* at build time,
#     so the upstream image ships key/host = undefined. We build with
#     __REVERB_*__ placeholders and /etc/entrypoint.d/50-reverb-config.sh swaps
#     in REVERB_APP_KEY / REVERB_HOST / REVERB_PORT / REVERB_SCHEME on boot.
#  2. Trust Railway's edge proxies (100.64.0.0/10) so X-Forwarded-Proto is
#     honoured and Livewire/passkey URLs are https.
# Upgrade: bump RELATICLE_TAG, tag the repo v<RELATICLE_TAG>-r<N>, CI pushes.
ARG RELATICLE_TAG=3.5.6
FROM ghcr.io/relaticle/relaticle:${RELATICLE_TAG} AS upstream

###########################################
# Rebuild frontend assets from the image's own sources, with placeholders
###########################################
FROM node:22-alpine AS frontend
WORKDIR /app
COPY --from=upstream /var/www/html/package.json /var/www/html/pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile --ignore-scripts
COPY --from=upstream /var/www/html/vite.config.js ./
COPY --from=upstream /var/www/html/resources ./resources
COPY --from=upstream /var/www/html/public ./public
COPY --from=upstream /var/www/html/packages ./packages
COPY --from=upstream /var/www/html/vendor ./vendor
COPY echo.js ./resources/js/echo.js

ENV VITE_REVERB_APP_KEY=__REVERB_APP_KEY__ \
    VITE_REVERB_HOST=__REVERB_HOST__ \
    VITE_REVERB_PORT=__REVERB_PORT__ \
    VITE_REVERB_SCHEME=__REVERB_SCHEME__
RUN pnpm run build \
 && for ph in __REVERB_APP_KEY__ __REVERB_HOST__ __REVERB_PORT__ __REVERB_SCHEME__; do grep -q "$ph" public/build/assets/echo-*.js || { echo "placeholder $ph folded away"; exit 1; }; done

###########################################
# Final image
###########################################
FROM upstream
USER root
RUN sed -i "s#'fe80::/10',#'fe80::/10',\n            '100.64.0.0/10', // Railway edge proxies#" /var/www/html/bootstrap/app.php \
 && grep -q "100.64.0.0/10" /var/www/html/bootstrap/app.php \
 && rm -rf /var/www/html/public/build
COPY --from=frontend --chown=www-data:www-data /app/public/build /var/www/html/public/build
COPY --chmod=755 entrypoint.d/ /etc/entrypoint.d/
USER www-data
