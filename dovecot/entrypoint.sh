#!/bin/sh
set -eu

: "${LOCAL_BRIDGE_USER:?LOCAL_BRIDGE_USER is required}"
: "${LOCAL_BRIDGE_PASS:?LOCAL_BRIDGE_PASS is required}"

# Render the passwd-file from env (kept out of the image/repo).
# Format: user:{scheme}password:uid:gid:...  (scheme set in dovecot.conf)
printf '%s:%s::::::\n' "$LOCAL_BRIDGE_USER" "$LOCAL_BRIDGE_PASS" > /etc/dovecot/users
# Dovecot's auth process runs as the 'dovecot' user and must be able to read
# this file; root-owned 600 gives it "Permission denied". Make it owner-readable.
chown dovecot:dovecot /etc/dovecot/users 2>/dev/null || true
chmod 640 /etc/dovecot/users

mkdir -p /mail
# The mail process runs as uid 1000; make sure it owns the maildir.
chown -R 1000:1000 /mail 2>/dev/null || true

exec dovecot -F
