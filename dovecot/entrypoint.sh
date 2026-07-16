#!/bin/sh
set -eu

: "${LOCAL_BRIDGE_USER:?LOCAL_BRIDGE_USER is required}"
: "${LOCAL_BRIDGE_PASS:?LOCAL_BRIDGE_PASS is required}"

# Render the passwd-file from env (kept out of the image/repo).
# Format: user:{scheme}password:uid:gid:...  (scheme set in dovecot.conf)
printf '%s:%s::::::\n' "$LOCAL_BRIDGE_USER" "$LOCAL_BRIDGE_PASS" > /etc/dovecot/users
chmod 600 /etc/dovecot/users

mkdir -p /mail

exec dovecot -F
