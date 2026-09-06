# Relaticle

Open-source CRM built for people and AI-powered work. This template deploys the full stack:

- **relaticle** — web app (nginx + php-fpm), migrations run on boot
- **horizon** — queue worker (chat, mail, imports)
- **scheduler** — cron
- **reverb** — websockets for realtime chat
- **Postgres** + **Redis**

## After deploy
1. Open the app URL and sign up. Email verification is off by default; set `REQUIRE_EMAIL_VERIFICATION=true` once `MAIL_*` is configured.
2. **AI chat**: set `OLLAMA_API_KEY` + `OLLAMA_MODEL` (Ollama cloud, e.g. `glm-5.3-flash`) or `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` on the `relaticle` service. Workers pick them up by reference.
3. **Google login**: create an OAuth client with redirect `https://<your-domain>/auth/callback/google`, set `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.
4. **Custom domain**: add it to `relaticle` with target port **8080**, then set `APP_URL` to it. Reverb's allowed origin follows `APP_URL`.

## Why a wrapper image?
The app runs `ghcr.io/tab58/relaticle-railway`, a thin layer over the official image that (a) injects the Reverb client config at boot instead of at build time and (b) trusts Railway's edge proxies so generated URLs are https. Source: https://github.com/tab58/relaticle-railway. Workers and Reverb run the official image.

## Upgrade
Bump the image tag on all four services to the same Relaticle version.
