# Pinned to the bullseye variant: newer Debian (bookworm/trixie) dropped
# libc-client-dev (UW-IMAP), which the PHP imap extension still needs.
FROM php:8.2-apache-bullseye

# Z-Push needs the IMAP extension; the IMAP backend's SMTP sender needs PEAR
# Mail/Net_SMTP. gettext-base provides envsubst for runtime config rendering.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git libc-client-dev libkrb5-dev libssl-dev gettext-base \
 && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
 && docker-php-ext-install imap \
 && pear install Mail Mail_mime Net_SMTP \
 && rm -rf /var/lib/apt/lists/*

# Pinned to the current maintained release (Jul 2025). Webroot is src/.
ARG ZPUSH_VERSION=2.7.6
RUN git clone --depth 1 --branch ${ZPUSH_VERSION} \
      https://github.com/Z-Hub/Z-Push.git /opt/z-push \
 && cp -a /opt/z-push/src/. /var/www/html/ \
 && rm -rf /opt/z-push \
 && mkdir -p /var/lib/z-push /var/log/z-push \
 && chown -R www-data:www-data /var/www/html /var/lib/z-push /var/log/z-push

COPY config.php        /var/www/html/config.php
COPY imap-config.php   /var/www/html/backend/imap/config.php
COPY zpush-apache.conf /etc/apache2/sites-available/000-default.conf
COPY entrypoint.sh     /usr/local/bin/bridge-entrypoint.sh
RUN chmod +x /usr/local/bin/bridge-entrypoint.sh && a2enmod rewrite alias

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/bridge-entrypoint.sh"]
