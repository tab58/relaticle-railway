import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

// Vite inlines VITE_* at build time. The wrapper image builds with
// __REVERB_*__ placeholders and /etc/entrypoint.d/50-reverb-config.sh swaps
// in the real REVERB_* env at container start. If a placeholder survives,
// fail loud instead of letting pusher-js throw and kill the module.
const key = import.meta.env.VITE_REVERB_APP_KEY;
const wsHost = import.meta.env.VITE_REVERB_HOST;
// Regex test: esbuild constant-folds `'__REVERB_SCHEME__' === 'https'` to false at
// build time (before the placeholder is substituted), but never evaluates regexes.
const forceTLS = /^https$/i.test(import.meta.env.VITE_REVERB_SCHEME ?? 'https');
const unset = (v) => !v || v.startsWith('__REVERB_');

if (unset(key) || unset(wsHost)) {
    console.error('[echo] REVERB_APP_KEY / REVERB_HOST not configured; realtime disabled.');
} else {
    window.Echo = new Echo({
        broadcaster: 'reverb',
        key,
        wsHost,
        wsPort: import.meta.env.VITE_REVERB_PORT ?? 80,
        wssPort: import.meta.env.VITE_REVERB_PORT ?? 443,
        forceTLS,
        enabledTransports: ['ws', 'wss'],
    });
}
