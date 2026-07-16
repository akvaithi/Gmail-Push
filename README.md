# Gmail → Apple Mail Push Bridge

Native **push** notifications for a Gmail account in the iOS Apple Mail app —
the way iCloud works, no manual checking, app closed.

Apple Mail can't push Gmail directly: Google shut off Exchange ActiveSync
(Google Sync) for **all** account types in 2025, so Gmail in Apple Mail is
stuck on 15-minute *Fetch*. This project doesn't try to spoof *Google's*
Exchange. Instead it runs **your own** Exchange ActiveSync server (Z-Push) that
iOS connects to and gets real push from, while an IMAP-IDLE "Gmail client"
quietly feeds it behind the scenes. iOS never talks to Gmail directly.

```
 Gmail ──IMAP IDLE──▶ watcher ──mbsync──▶ [maildata] ◀──IMAP── dovecot
                                                                  ▲
 iOS Apple Mail ◀══EAS push══ caddy(TLS) ──▶ zpush ───IMAP───────┘
                                              │
                                              └──SMTP──▶ postfix ──▶ smtp.gmail.com
```

Only the **watcher** holds a connection to Google (one silent IDLE), so the
Exchange push loop never hammers Gmail.

---

## What you need first

1. **A Linux server that's reachable from the internet** with:
   - A **DNS name** pointing at it, e.g. `push.yourdomain.com` (an A record).
   - **Ports 443 and 80 open** (443 = EAS/TLS, 80 = Let's Encrypt challenge).
   - Docker + Docker Compose.
2. **A Gmail App Password** (see below). Requires 2-Step Verification on the account.

> iOS **requires valid HTTPS** for Exchange. Caddy gets a free Let's Encrypt
> cert automatically for your DNS name — you just need the name to resolve and
> port 80/443 reachable.

### Create a Gmail App Password

1. Enable **2-Step Verification**: <https://myaccount.google.com/security>
2. Go to **App passwords**: <https://myaccount.google.com/apppasswords>
3. Create one (name it e.g. "push-bridge"). Copy the 16-character value.
4. That single value is used for IMAP IDLE, mbsync, **and** the Postfix relay.

---

## Setup

```bash
git clone https://github.com/akvaithi/Gmail-Push.git
cd Gmail-Push
cp .env.example .env
$EDITOR .env          # fill in BRIDGE_FQDN, ACME_EMAIL, GMAIL_ADDRESS,
                      # GMAIL_APP_PASSWORD, and a strong LOCAL_BRIDGE_PASS
docker compose up -d
docker compose logs -f watcher zpush caddy
```

Images are published publicly to **GHCR** by CI, so `docker compose up` pulls
them without building. To build locally instead: `docker compose up -d --build`.

### Point iOS at the bridge (manual Exchange setup)

On the iPhone/iPad:

1. **Settings → Apps → Mail → Mail Accounts → Add Account → Microsoft Exchange**
2. **Email:** your Gmail address (this becomes your From). **Description:** anything.
3. Tap **Next** → when prompted, choose **Configure Manually** (do *not* "Sign In" —
   that tries Google/Microsoft OAuth, which won't work here).
4. Enter:
   - **Server:** your `BRIDGE_FQDN` (e.g. `push.yourdomain.com`)
   - **Domain:** leave blank
   - **Username:** your `LOCAL_BRIDGE_USER`
   - **Password:** your `LOCAL_BRIDGE_PASS`
5. Save. Keep **Mail** on (Contacts/Calendars off for now — see Phase 2).

---

## Verify it works

| Check | Expected |
|---|---|
| `docker compose ps` | all services `running` |
| `docker compose logs watcher` | `IDLE established` |
| `curl -i https://BRIDGE_FQDN/Microsoft-Server-ActiveSync` | `401` (EAS auth challenge = TLS + endpoint live) |
| iOS account syncs INBOX | mail appears in Apple Mail |
| **Push test:** lock phone, close Mail, send yourself an email | notification within ~1 min |
| **Send test:** reply from iOS | recipient gets it from your Gmail address; copy lands in Gmail Sent |

---

## Tuning & options

- **Push latency** is bounded by `PING_INTERVAL` (Z-Push ↔ Dovecot, default 30s)
  plus `SYNC_INTERVAL` (watcher safety-net sync, default 45s). Lower them in
  `.env` for snappier push at the cost of a little more CPU.
- **Two-way sync (mark read / delete on iPhone → Gmail).** v1 ships **pull-only**
  (safe). To make the iPhone a true controller, edit
  [`watcher/mbsyncrc.template`](watcher/mbsyncrc.template): change `Sync Pull`
  to `Sync All` and rebuild the watcher. ⚠️ This lets deletions propagate to
  Gmail — test with a throwaway message first.
- **More than one Gmail account?** Run one copy of this stack per account
  (separate directory + `.env` + `BRIDGE_FQDN` subdomain), and add a separate
  Exchange account on iOS for each.

---

## Phase 2 — Calendar (and Contacts) push

EAS carries calendar/contacts on the same connection, so the bridge can also fix
slow Google Calendar syncs (invites **push** into Apple Calendar; accept/decline
flows back). This switches Z-Push to the **Combined** backend (IMAP for mail +
**CalDAV** for calendar). The one extra: Google CalDAV needs **OAuth2** (a Google
Cloud OAuth client + refresh token), not the mail App Password. Tracked as a
follow-up once Phase 1 mail push is confirmed working.

---

## Security notes

- **Public repo, zero secrets in git.** Real credentials live only in `.env`
  (gitignored). Only `.env.example` is committed. Nothing is baked into images.
- You're exposing an Exchange endpoint publicly — use a long random
  `LOCAL_BRIDGE_PASS`, keep HTTPS-only, and consider fail2ban on the host.

## Components

| Service | Image | Role |
|---|---|---|
| watcher | `ghcr.io/akvaithi/gmail-push-watcher` | IMAP IDLE + mbsync fetch |
| dovecot | `ghcr.io/akvaithi/gmail-push-dovecot` | local IMAP over the Maildir |
| zpush   | `ghcr.io/akvaithi/gmail-push-zpush`   | Exchange ActiveSync front end |
| postfix | `bokysan/postfix` (upstream) | send-only relay to Gmail SMTP |
| caddy   | `caddy:2-alpine` (upstream) | public TLS termination |

> **Note on Z-Push vs grommunio-sync:** classic Z-Push (used here) is the most
> straightforward to containerize. `grommunio-sync` is the actively-maintained
> successor and a documented drop-in if you'd rather run that.

## License

MIT
