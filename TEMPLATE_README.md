# Deploy and Host Relaticle on Railway

Relaticle is an open-source CRM built for people and AI-powered work: contacts, companies, opportunities, tasks, notes, custom fields, and an AI chat assistant that can read and update your CRM. This template deploys the full stack in one click.

## About Hosting Relaticle

The template provisions six services:

- **relaticle** — the web app (nginx + php-fpm). Runs migrations and caches on boot, healthcheck on `/up`.
- **horizon** — Laravel Horizon queue worker (chat, mail, imports).
- **scheduler** — Laravel scheduler.
- **reverb** — Laravel Reverb websocket server for realtime chat, on its own public domain.
- **Postgres** and **Redis** with volumes.

All secrets (`APP_KEY`, Reverb credentials) are generated at deploy time and shared to the workers by reference, so every service sees the same values.

The app runs `ghcr.io/tab58/relaticle-railway`, a thin layer over the official image that (a) injects the Reverb client config at boot instead of at build time and (b) trusts Railway's edge proxies so generated URLs are https. Source: https://github.com/tab58/relaticle-railway. Workers and Reverb run the official image.

## Why Deploy Relaticle on Railway

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Relaticle on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

## Common Use Cases

- Self-hosted CRM for a small team that wants data ownership.
- AI-assisted sales pipeline: chat with your CRM using Ollama cloud, OpenAI, or Anthropic models.
- Realtime collaboration on deals and tasks via websockets.

## Dependencies for Relaticle Hosting

- Postgres 18 and Redis 8 (provisioned by the template).
- Optional: an AI provider key, Google OAuth credentials, an SMTP mailbox.

### Deployment Dependencies

- Relaticle: https://github.com/Relaticle/relaticle
- Wrapper image: https://github.com/tab58/relaticle-railway
- Laravel Reverb: https://laravel.com/docs/reverb
- Ollama cloud: https://ollama.com

### After deploy

1. Open the app URL and sign up. Email verification is off by default; set `REQUIRE_EMAIL_VERIFICATION=true` once `MAIL_*` is configured.
2. **AI chat**: set `OLLAMA_API_KEY` + `OLLAMA_MODEL` (Ollama cloud, e.g. `glm-5.3-flash`) or `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` on the `relaticle` service, then redeploy `horizon` (workers copy referenced vars at boot; chat jobs 401 until restarted).
3. **Google login**: create an OAuth client with redirect `https://<your-domain>/auth/callback/google`, set `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.
4. **Custom domain**: add it to `relaticle` with target port **8080**, then set `APP_URL` to it and redeploy `reverb`, `horizon` and `scheduler` (they copy `APP_URL` at boot; Reverb rejects websocket connections from any other origin until restarted).

### Upgrade

Bump the image tag on all four app services to the same Relaticle version.
