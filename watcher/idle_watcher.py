#!/usr/bin/env python3
"""
Gmail IMAP IDLE watcher.

Holds ONE persistent IMAP IDLE connection to Gmail's INBOX. When Gmail signals
activity it triggers `mbsync` to pull the change into the shared Maildir, which
Dovecot serves and Z-Push pushes to iOS. A background thread also runs mbsync
every SYNC_INTERVAL seconds as a safety net (and, once two-way sync is enabled,
to propagate iPhone-side flag/delete changes back up to Gmail).

Only this process talks to Google — keeping the EAS ping loop off Gmail entirely.
"""
import os
import ssl
import subprocess
import sys
import threading
import time

from imapclient import IMAPClient

HOST = "imap.gmail.com"
USER = os.environ["GMAIL_ADDRESS"]
PASSWORD = os.environ["GMAIL_APP_PASSWORD"]
SYNC_INTERVAL = int(os.environ.get("SYNC_INTERVAL", "45"))
MBSYNC_CFG = "/root/.mbsyncrc"

# IMAP IDLE must be refreshed well under the server's 29-minute limit.
IDLE_REFRESH = 5 * 60

_sync_lock = threading.Lock()


def log(msg: str) -> None:
    print(f"[watcher] {msg}", flush=True)


def run_mbsync(reason: str) -> None:
    """Serialize mbsync runs so IDLE-triggered and periodic syncs never overlap."""
    with _sync_lock:
        log(f"mbsync ({reason})")
        try:
            subprocess.run(
                ["mbsync", "-c", MBSYNC_CFG, "gmail"],
                check=True,
                capture_output=True,
                text=True,
                timeout=300,
            )
        except subprocess.CalledProcessError as e:
            log(f"mbsync failed rc={e.returncode}: {e.stderr.strip()}")
        except subprocess.TimeoutExpired:
            log("mbsync timed out")
        # Dovecot serves mail as uid 1000; hand it ownership of what we synced.
        subprocess.run(["chown", "-R", "1000:1000", "/mail"], check=False)


def periodic_sync() -> None:
    while True:
        time.sleep(SYNC_INTERVAL)
        run_mbsync("periodic")


def idle_loop() -> None:
    context = ssl.create_default_context()
    while True:
        try:
            log(f"connecting to {HOST} as {USER}")
            with IMAPClient(HOST, ssl=True, ssl_context=context) as client:
                client.login(USER, PASSWORD)
                client.select_folder("INBOX")
                log("IDLE established")
                while True:
                    client.idle()
                    # Block until Gmail reports activity or refresh window elapses.
                    responses = client.idle_check(timeout=IDLE_REFRESH)
                    client.idle_done()
                    if responses:
                        log(f"IDLE activity: {responses}")
                        run_mbsync("idle")
                    else:
                        # Timeout: loop re-issues IDLE to keep the connection warm.
                        pass
        except Exception as e:  # noqa: BLE001 — resilience over precision here
            log(f"IDLE connection error: {e!r}; reconnecting in 15s")
            time.sleep(15)


def main() -> int:
    threading.Thread(target=periodic_sync, daemon=True).start()
    idle_loop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
