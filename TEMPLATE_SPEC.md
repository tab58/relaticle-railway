# Template editor spec — `relaticle` (railway.com/deploy/relaticle)

Apply in Railway → Templates → relaticle → Edit. Six services. Every shared value is a
reference, never a literal. `B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"`.

## relaticle (app)
- Source: image `ghcr.io/tab58/relaticle-railway:3.5.6`
- Networking: HTTP, port **8080**, generate domain
- Healthcheck path: `/up`
- Volume: `/var/www/html/storage/app`
- Variables
  | key | value |
  |---|---|
  | APP_KEY | `base64:${{secret(43, "B64")}}=` |
  | APP_NAME | `Relaticle` |
  | APP_ENV | `production` |
  | APP_DEBUG | `false` |
  | APP_TIMEZONE | `UTC` |
  | APP_URL | `https://${{RAILWAY_PUBLIC_DOMAIN}}` |
  | LOG_CHANNEL | `stderr` |
  | LOG_LEVEL | `warning` |
  | REQUIRE_EMAIL_VERIFICATION | `false` (prompt; note: needs MAIL_* if true) |
  | DB_CONNECTION | `pgsql` |
  | DB_HOST / DB_PORT / DB_DATABASE / DB_USERNAME / DB_PASSWORD | `${{pg-relaticle.PGHOST}}` / `${{pg-relaticle.PGPORT}}` / `${{pg-relaticle.PGDATABASE}}` / `${{pg-relaticle.PGUSER}}` / `${{pg-relaticle.PGPASSWORD}}` |
  | REDIS_HOST / REDIS_PORT / REDIS_PASSWORD | `${{redis-relaticle.REDISHOST}}` / `${{redis-relaticle.REDISPORT}}` / `${{redis-relaticle.REDISPASSWORD}}` |
  | CACHE_STORE / SESSION_DRIVER / QUEUE_CONNECTION | `redis` |
  | BROADCAST_CONNECTION | `reverb` |
  | REVERB_APP_ID | `${{secret(8, "0123456789")}}` |
  | REVERB_APP_KEY | `${{secret(40, "0123456789abcdef")}}` |
  | REVERB_APP_SECRET | `${{secret(64, "0123456789abcdef")}}` |
  | REVERB_HOST | `${{reverb.RAILWAY_PUBLIC_DOMAIN}}` |
  | REVERB_PORT / REVERB_SCHEME | `443` / `https` |
  | AUTORUN_ENABLED / AUTORUN_LARAVEL_MIGRATION / AUTORUN_LARAVEL_MIGRATION_ISOLATION | `true` |
  | MAIL_MAILER | `log` (prompt: set `smtp` + MAIL_* to send mail) |
  | MAIL_HOST / MAIL_PORT / MAIL_USERNAME / MAIL_PASSWORD / MAIL_ENCRYPTION | prompts, defaults ``/`587`/``/``/`tls` |
  | MAIL_FROM_ADDRESS / MAIL_FROM_NAME | prompts, defaults `hello@example.com` / `Relaticle` |
  | OLLAMA_BASE_URL | `https://ollama.com` |
  | OLLAMA_API_KEY / OLLAMA_MODEL | prompts, empty (desc: "Ollama cloud key + tool-capable model tag, e.g. glm-5.3-flash") |
  | OPENAI_API_KEY / ANTHROPIC_API_KEY | prompts, empty (optional) |
  | GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET | prompts, empty (optional) |
  | GOOGLE_REDIRECT_URI | `https://${{RAILWAY_PUBLIC_DOMAIN}}/auth/callback/google` |

## horizon
- Source: image `ghcr.io/relaticle/relaticle:3.5.6`; start command `php artisan horizon`; no networking; no healthcheck
- Variables: `AUTORUN_ENABLED=false`; everything else `${{relaticle.X}}` for X in
  APP_KEY APP_NAME APP_ENV APP_DEBUG APP_URL LOG_CHANNEL REQUIRE_EMAIL_VERIFICATION
  DB_CONNECTION DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD
  REDIS_HOST REDIS_PORT REDIS_PASSWORD CACHE_STORE QUEUE_CONNECTION
  BROADCAST_CONNECTION REVERB_APP_ID REVERB_APP_KEY REVERB_APP_SECRET REVERB_HOST REVERB_PORT REVERB_SCHEME
  OLLAMA_BASE_URL OLLAMA_API_KEY OLLAMA_MODEL OPENAI_API_KEY ANTHROPIC_API_KEY
  MAIL_MAILER MAIL_HOST MAIL_PORT MAIL_USERNAME MAIL_PASSWORD MAIL_ENCRYPTION MAIL_FROM_ADDRESS MAIL_FROM_NAME

## scheduler
- Same as horizon, start command `php artisan schedule:work`.

## reverb
- Source: image `ghcr.io/relaticle/relaticle:3.5.6`; start command `php artisan reverb:start`
- Networking: HTTP, port **8080**, generate domain. No healthcheck.
- Variables: `AUTORUN_ENABLED=false`, `REVERB_HOST=${{RAILWAY_PUBLIC_DOMAIN}}`, `REVERB_PORT=443`, `REVERB_SCHEME=https`,
  `CACHE_STORE=redis`, and `${{relaticle.X}}` for X in
  APP_KEY APP_ENV APP_URL LOG_CHANNEL REVERB_APP_ID REVERB_APP_KEY REVERB_APP_SECRET
  DB_CONNECTION DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PORT REDIS_PASSWORD

## pg-relaticle / redis-relaticle
- Railway Postgres / Redis templates, volumes attached. Unchanged.

## Sanity before publishing
- No literal secrets anywhere (search the editor for your real APP_KEY / REVERB key prefixes).
- Both public services on port 8080.
- Image tags: app on `tab58/relaticle-railway:3.5.6`, the other three on `relaticle/relaticle:3.5.6` — same upstream version.
