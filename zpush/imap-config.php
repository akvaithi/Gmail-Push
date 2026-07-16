<?php
/**
 * Z-Push IMAP backend config (bridge build).
 * Talks to the local Dovecot (which serves the Maildir the watcher fills),
 * and relays outbound mail through the local Postfix container.
 * Credentials come from the DEVICE (iOS Exchange user/pass = LOCAL_BRIDGE_*).
 */
    define('IMAP_SERVER', 'dovecot');
    define('IMAP_PORT', 143);
    // Plain IMAP inside the docker network (no TLS needed hop-internally).
    define('IMAP_OPTIONS', '/notls/norsh');

    // The device's account email becomes the From address (your Gmail address).
    define('IMAP_DEFAULTFROM', '');

    define('IMAP_FOLDER_CONFIGURED', false);

    // --- Outbound: hand mail to the Postfix relay over SMTP submission ---
    define('IMAP_SMTP_METHOD', 'smtp');
    global $imap_smtp_params;
    $imap_smtp_params = array(
        'host' => 'postfix',
        'port' => 587,
        'auth' => false,   // Postfix relays to Gmail with the App Password
    );

    define('MServerActiveSyncVersion', '14.1');
