#!/bin/sh
set -eu

: "${GMAIL_ADDRESS:?GMAIL_ADDRESS is required}"
: "${GMAIL_APP_PASSWORD:?GMAIL_APP_PASSWORD is required}"

# Render mbsyncrc with real credentials (kept out of the image/repo).
export GMAIL_ADDRESS GMAIL_APP_PASSWORD
envsubst '${GMAIL_ADDRESS} ${GMAIL_APP_PASSWORD}' \
  < /app/mbsyncrc.template > /root/.mbsyncrc
chmod 600 /root/.mbsyncrc

mkdir -p /mail

# Initial sync so the mailbox is populated before iOS first connects.
echo "[watcher] initial mbsync..."
mbsync -c /root/.mbsyncrc gmail || echo "[watcher] initial sync failed (will retry on IDLE)"
# Dovecot serves mail as uid 1000; give it ownership of the synced maildir.
chown -R 1000:1000 /mail 2>/dev/null || true

exec python3 -u /app/idle_watcher.py
