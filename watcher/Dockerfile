FROM python:3.12-slim

# isync provides `mbsync`; gettext-base provides `envsubst` for config rendering.
RUN apt-get update \
 && apt-get install -y --no-install-recommends isync ca-certificates gettext-base \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir imapclient==3.0.1

WORKDIR /app
COPY idle_watcher.py /app/idle_watcher.py
COPY mbsyncrc.template /app/mbsyncrc.template
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
