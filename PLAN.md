# Plan: fold the Railway fixes into the `relaticle` template

Target: your published template at https://railway.com/deploy/relaticle (code `relaticle`).
Goal: a fresh deploy from the template works end to end (login, realtime chat, queue, mail-ready) with zero manual patching.

## What went wrong on a fresh deploy (all must be prevented by the template)

| # | Symptom | Root cause | Template-level fix |
|---|---------|-----------|--------------------|
| 1 | 500 on every request | `APP_KEY` generator produced wrong length (aes-256-cbc needs 32 bytes) | `APP_KEY=base64:${{secret(43, "ABC…xyz0123456789+/")}}=` on app; horizon/scheduler/reverb use `${{relaticle.APP_KEY}}` |
| 2 | 502 on custom domain | Domain target port 9000 (php-fpm) | Template can't set custom domains. Service domain must be generated on **8080**; README tells users to use 8080 for custom domains |
| 3 | Login buttons dead (mixed content) | Upstream trusts only RFC1918; Railway edge is 100.64.0.0/10 | Wrapper image patches `bootstrap/app.php` (until upstream accepts `TRUSTED_PROXIES` env) |
| 4 | Google login 400 | `GOOGLE_*` unset | Optional template prompts `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`; `GOOGLE_REDIRECT_URI=https://${{RAILWAY_PUBLIC_DOMAIN}}/auth/callback/google` |
| 5 | Realtime never connects | Vite inlined `VITE_REVERB_*` as `undefined` at image build | Wrapper image builds with placeholders and substitutes real values at container start (see §2) |
| 6 | No websocket server | Upstream compose/template has no Reverb service | Add `reverb` service to template |
| 7 | Chat 401 | No AI provider key | Optional prompts `OLLAMA_API_KEY`/`OLLAMA_MODEL` (+ `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`) shared to horizon by reference |
| 8 | Worker used stale key | horizon/scheduler had literal `APP_KEY` copies | All shared vars are `${{relaticle.X}}` references, never literals |

## Phase 1 — Wrapper image published to a registry (unblocks everything)

Why an image and not a repo source: templates that build from a GitHub repo make every deployer clone/fork and build. An image keeps the template one-click and matches how it works today.

1. Create public GitHub repo `relaticle-railway` from `~/Documents/code/relaticle-railway/`.
2. Change the Dockerfile so `VITE_REVERB_*` are **placeholders**, not real values:
   - `ARG VITE_REVERB_APP_KEY=__REVERB_APP_KEY__`, `VITE_REVERB_HOST=__REVERB_HOST__`, `VITE_REVERB_PORT=__REVERB_PORT__`, `VITE_REVERB_SCHEME=__REVERB_SCHEME__`.
   - Drop the "must be set" guard (placeholders are always set).
3. Add `entrypoint.d/50-reverb-config.sh` (copied with `--chmod=755` to `/etc/entrypoint.d/`):
   ```sh
   #!/bin/sh
   # ponytail: runtime substitution of Vite build-time constants. Upstream fix = read Reverb config from a <meta> tag at runtime.
   set -e
   f=$(ls /var/www/html/public/build/assets/echo-*.js)
   sed -i "s|__REVERB_APP_KEY__|${REVERB_APP_KEY}|g; s|__REVERB_HOST__|${REVERB_HOST}|g; s|__REVERB_PORT__|${REVERB_PORT:-443}|g; s|__REVERB_SCHEME__|${REVERB_SCHEME:-https}|g" "$f"
   ```
   Keep the guarded `echo.js` (logs a clear error if a placeholder survives).
4. GitHub Actions workflow: on tag `v3.5.6-r1` (upstream tag + revision) build `linux/amd64` and push `ghcr.io/<you>/relaticle-railway:3.5.6` and `:latest`. Package visibility public.
5. Verify locally: `docker run -e REVERB_APP_KEY=abc -e REVERB_HOST=x.up.railway.app … --entrypoint sh` then `tail -c 300 public/build/assets/echo-*.js` shows the values after `/etc/entrypoint.d/50-reverb-config.sh` runs.

Check: one runnable test script `test.sh` in the repo that builds the image, runs the entrypoint script with dummy env, and asserts the substituted values are present. Fails if the placeholder survives.

## Phase 2 — Move the live project onto the image (so the template can be regenerated from it)

1. Railway UI → `relaticle` → Settings → Source → Docker image `ghcr.io/<you>/relaticle-railway:3.5.6`. Remove the `VITE_REVERB_*` variables (no longer needed).
2. Redeploy, re-verify: `curl -s https://crm.successr.team/build/assets/echo-*.js | tail -c 300` shows key + host; login works; `window.Echo.connector.pusher.connection.state === 'connected'`.
3. Tidy the project so the generated template is clean:
   - Delete stray `VITE_*` and `BROADCAST_CONNECTION` from `reverb`.
   - Add healthcheck path `/up` on `relaticle`.
   - Confirm `reverb` source is the upstream image (or the wrapper; either works) with start command `php artisan reverb:start`, service domain on port 8080.

## Phase 3 — Regenerate the template from the project

1. `railway templates create --project successr-ai --environment devtools --json` → unpublished draft that mirrors the fixed project.
2. In the template editor, per service:

   **relaticle** (app)
   - Source: `ghcr.io/<you>/relaticle-railway:3.5.6`.
   - Public networking: HTTP, port **8080**. Healthcheck `/up`.
   - Variables (generated/derived, not literals):
     - `APP_KEY=base64:${{secret(43, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")}}=`
     - `APP_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}`
     - `REVERB_APP_ID=${{secret(8, "0123456789")}}`, `REVERB_APP_KEY=${{secret(40, "0123456789abcdef")}}`, `REVERB_APP_SECRET=${{secret(64, "0123456789abcdef")}}`
     - `REVERB_HOST=${{reverb.RAILWAY_PUBLIC_DOMAIN}}`, `REVERB_PORT=443`, `REVERB_SCHEME=https`, `BROADCAST_CONNECTION=reverb`
     - `DB_*`/`REDIS_*` → `${{pg-relaticle.*}}` / `${{redis-relaticle.*}}` references
     - `QUEUE_CONNECTION=redis`, `CACHE_STORE=redis`, `SESSION_DRIVER=redis`, `LOG_CHANNEL=stderr`
     - Optional prompts (empty default, described): `OLLAMA_API_KEY`, `OLLAMA_MODEL`, `OLLAMA_BASE_URL=https://ollama.com`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `MAIL_MAILER`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDRESS`
     - `GOOGLE_REDIRECT_URI=https://${{RAILWAY_PUBLIC_DOMAIN}}/auth/callback/google`
   - Remove any literal secret the generator copied from your project.

   **horizon** / **scheduler**
   - Same upstream image tag; start commands `php artisan horizon` / `php artisan schedule:work`; `AUTORUN_ENABLED=false`.
   - Every var is a `${{relaticle.X}}` reference (APP_KEY, APP_URL, DB_*, REDIS_*, REVERB_*, BROADCAST_CONNECTION, OLLAMA_*, OPENAI/ANTHROPIC keys, MAIL_*).

   **reverb** (new)
   - Upstream image, start command `php artisan reverb:start`, public networking HTTP port **8080**, no healthcheck.
   - `REVERB_HOST=${{RAILWAY_PUBLIC_DOMAIN}}`, rest `${{relaticle.X}}` references, `AUTORUN_ENABLED=false`.

   **pg-relaticle / redis-relaticle** unchanged (volumes attached).

3. Template README (`--readme-file`): what gets deployed, the 8080 rule for custom domains, how to turn on Google login / Ollama / mail, how to upgrade (bump image tags on 4 services).
4. `railway templates publish <id> --readme-file TEMPLATE_README.md --description …`.

## Phase 4 — Prove it

1. Deploy the draft into a **new** throwaway Railway project. Do not touch anything by hand.
2. Checklist: `/` → 200; login page has no console errors; `echo-*.js` tail shows real key + reverb host; `curl` websocket handshake to reverb with `Origin: https://<app domain>` → 101; email login reaches "check your email"/password step; horizon log shows jobs DONE; with an Ollama key set, one chat message round-trips.
3. Delete throwaway project. Publish.

## Phase 5 — Upstream (removes the wrapper eventually)

Open against Relaticle/relaticle, referencing their merged PR #256 (trust private-network proxies):
1. `TRUSTED_PROXIES` env (comma list or `*`) merged into the hardcoded list in `bootstrap/app.php`. Tiny, likely accepted.
2. Reverb client config at runtime: blade emits `<meta name="reverb-config" content='{"key":…,"host":…}'>` and `echo.js` reads it, so the published image works for any host. Bigger; mention Railway/Fly/Render all hit this.
3. `compose.yml`: add a `reverb` service (there is none today).
4. Docs: Railway deployment notes (8080, proxies, reverb).
When 1+2 ship, the template swaps back to `ghcr.io/relaticle/relaticle:<tag>` and this wrapper repo is archived.

## Risks / decisions

- **Placeholder sed hack** touches a built asset at boot. Content-hash in the filename no longer matches content; harmless (per-deploy constant), but note it. Upstream fix (§5.2) is the real solution.
- **Template generator variables**: confirm `${{secret(len, alphabet)}}` and cross-service refs render in the editor as expected before publishing; test by deploying (Phase 4).
- **GHCR image ownership**: template depends on your registry staying public. Alternative is Docker Hub. Pick one.
- **Version skew**: app runs the wrapper tag, horizon/scheduler/reverb run the upstream tag. Keep the same upstream version in both; README says so.
- **Anton Orel's marketplace template** (`relaticle-agent-native-crm`) exists, not by the maintainers. Yours will be the one that actually works; consider asking Relaticle to link it from their README once Phase 4 passes.

## Order of work

Phase 1 (image, ~1 hr) → Phase 2 (switch prod, 15 min) → Phase 3 (template, ~1 hr) → Phase 4 (test deploy, 30 min) → Phase 5 (upstream PRs, async).
