# relaticle-railway

Wrapper image for running [Relaticle](https://github.com/Relaticle/relaticle) on Railway
(or any host that terminates TLS at a proxy). Published as `ghcr.io/<owner>/relaticle-railway:<version>`.

## What it fixes
1. **Reverb client config at runtime.** Upstream bakes `VITE_REVERB_*` into the JS bundle at
   image build, so realtime chat never connects from the stock image. This image builds with
   placeholders and `entrypoint.d/50-reverb-config.sh` injects `REVERB_APP_KEY/HOST/PORT/SCHEME`
   on boot. Same env vars you already set for the server side.
2. **Trusts Railway edge proxies** (`100.64.0.0/10`) so `X-Forwarded-Proto` is honoured and
   Livewire/passkey URLs are `https`.

## Services (mirrors upstream compose.yml + reverb)
| service   | image            | start command                  | notes                          |
|-----------|------------------|--------------------------------|--------------------------------|
| relaticle | this image       | default                        | HTTP on **8080**, healthcheck `/up` |
| horizon   | upstream image   | `php artisan horizon`          | `AUTORUN_ENABLED=false`        |
| scheduler | upstream image   | `php artisan schedule:work`    | `AUTORUN_ENABLED=false`        |
| reverb    | upstream image   | `php artisan reverb:start`     | public domain on **8080**, `AUTORUN_ENABLED=false` |
| postgres, redis | Railway plugins |                           |                                |

Custom domains must target port **8080** (nginx), not 9000 (php-fpm).

## Required app vars
`APP_KEY` (`base64:` + 32 random bytes), `APP_URL`, `DB_*`, `REDIS_*`, `QUEUE_CONNECTION=redis`,
`BROADCAST_CONNECTION=reverb`, `REVERB_APP_ID/KEY/SECRET`, `REVERB_HOST=<reverb public domain>`,
`REVERB_PORT=443`, `REVERB_SCHEME=https`. horizon/scheduler/reverb reference the app's values.
Optional: `OLLAMA_BASE_URL=https://ollama.com` + `OLLAMA_API_KEY` + `OLLAMA_MODEL` (or
`OPENAI_API_KEY` / `ANTHROPIC_API_KEY`), `GOOGLE_CLIENT_ID/SECRET` + `GOOGLE_REDIRECT_URI`, `MAIL_*`.

## Develop
```
./test.sh                # build + assert substitution and proxy patch
```

## Release
Bump `RELATICLE_TAG` in the Dockerfile, then `git tag v<upstream>-r<n> && git push --tags`.
CI publishes `:<upstream>-r<n>`, `:<upstream>`, `:latest`.

## Railway CLI gotchas
- `railway add` re-links the current dir to the new service. Always pass `-s <service>`.
- `railway up` uploads the linked project's root, not cwd.
- Build logs: `railway logs <deployId> --build`.
