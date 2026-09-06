# relaticle service: variables that are new or changed vs the current published template

| key | default | optional | description |
|---|---|---|---|
| ANTHROPIC_API_KEY | `` | True | Anthropic API key for Claude models. Optional. |
| APP_KEY | `base64:${{secret(43, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")}}=` | False | Laravel encryption key (auto-generated, 32 bytes). |
| BROADCAST_CONNECTION | `reverb` | False | Realtime broadcasting driver. |
| GOOGLE_CLIENT_ID | `` | True | Google OAuth client id for 'Continue with Google'. Optional. |
| GOOGLE_CLIENT_SECRET | `` | True | Google OAuth client secret. Optional. |
| GOOGLE_REDIRECT_URI | `https://${{RAILWAY_PUBLIC_DOMAIN}}/auth/callback/google` | True | Register this as the authorized redirect URI in Google Cloud. |
| OLLAMA_API_KEY | `` | True | Ollama cloud API key (https://ollama.com/settings/keys). Leave empty to skip. |
| OLLAMA_BASE_URL | `https://ollama.com` | True | Ollama endpoint. Default is Ollama cloud. |
| OLLAMA_MODEL | `` | True | Tool-capable Ollama model tag, e.g. glm-5.3-flash or gpt-oss:120b. Adds it to the chat model picker. |
| OPENAI_API_KEY | `` | True | OpenAI API key for chat models. Optional. |
| REQUIRE_EMAIL_VERIFICATION | `false` | True | Require email verification on signup. Needs MAIL_* configured when true. |
| REVERB_APP_ID | `${{secret(8, "0123456789")}}` | False | Reverb app id (auto-generated). |
| REVERB_APP_KEY | `${{secret(40, "0123456789abcdef")}}` | False | Reverb public key (auto-generated). Injected into the JS bundle at boot. |
| REVERB_APP_SECRET | `${{secret(64, "0123456789abcdef")}}` | False | Reverb secret (auto-generated). |
| REVERB_HOST | `${{reverb.RAILWAY_PUBLIC_DOMAIN}}` | False | Public host of the reverb service. |
| REVERB_PORT | `443` | False | Reverb public port (Railway terminates TLS). |
| REVERB_SCHEME | `https` | False | Reverb public scheme. |

Remove: VITE_REVERB_APP_KEY, VITE_REVERB_HOST, VITE_REVERB_PORT, VITE_REVERB_SCHEME (if present).
