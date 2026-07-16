#!/bin/sh
set -eu

: "${PING_INTERVAL:=30}"
export PING_INTERVAL

# Render PING_INTERVAL into the Z-Push config (only that token is substituted).
tmp="$(mktemp)"
envsubst '${PING_INTERVAL}' < /var/www/html/config.php > "$tmp"
mv "$tmp" /var/www/html/config.php

mkdir -p /var/lib/z-push /var/log/z-push
chown -R www-data:www-data /var/lib/z-push /var/log/z-push

exec apache2-foreground
