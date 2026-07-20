#!/bin/sh
set -eu

: "${PING_INTERVAL:=30}"
: "${PING_HIGHER_BOUND_LIFETIME:=90}"
export PING_INTERVAL PING_HIGHER_BOUND_LIFETIME

# Render the templated tokens into the Z-Push config.
tmp="$(mktemp)"
envsubst '${PING_INTERVAL} ${PING_HIGHER_BOUND_LIFETIME}' < /var/www/html/config.php > "$tmp"
mv "$tmp" /var/www/html/config.php
# mktemp creates 0600 root; Apache runs as www-data and must be able to read it.
chown www-data:www-data /var/www/html/config.php
chmod 644 /var/www/html/config.php

mkdir -p /var/lib/z-push /var/log/z-push
chown -R www-data:www-data /var/lib/z-push /var/log/z-push

exec apache2-foreground
