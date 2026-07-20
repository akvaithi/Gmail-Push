<?php
/**
 * Z-Push main configuration (bridge build).
 * Only the settings that differ from stock defaults are set here.
 * PING_INTERVAL is substituted from the environment at container start.
 */
    define('TIMEZONE', 'UTC');
    define('STATE_DIR', '/var/lib/z-push/');
    define('LOGFILEDIR', '/var/log/z-push/');
    define('LOGFILE', LOGFILEDIR . 'z-push.log');
    define('LOGERRORFILE', LOGFILEDIR . 'z-push-error.log');
    define('LOGLEVEL', LOGLEVEL_INFO);

    define('USE_FULLEMAIL_FOR_LOGIN', false);

    // Push heartbeat: how often Z-Push re-checks the backend during a Ping.
    // This is the practical ceiling on push latency (seconds).
    define('PING_INTERVAL', ${PING_INTERVAL});

    // Cap how long a single Ping is held open. Behind a Cloudflare Tunnel/proxy
    // the edge returns 524 after ~100s, so keep this under that (e.g. 90): Z-Push
    // answers "no changes" first and iOS immediately re-pings. Harmless on a
    // direct connection too.
    define('PING_HIGHER_BOUND_LIFETIME', ${PING_HIGHER_BOUND_LIFETIME});

    define('SYNC_MAX_ITEMS', 512);
    define('UNSET_UNCHANGED_ITEMS', true);

    define('BACKEND_PROVIDER', 'BackendIMAP');
