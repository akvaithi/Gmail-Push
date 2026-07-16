FROM dovecot/dovecot:2.3-latest

COPY dovecot.conf /etc/dovecot/dovecot.conf
COPY entrypoint.sh /usr/local/bin/bridge-entrypoint.sh
RUN chmod +x /usr/local/bin/bridge-entrypoint.sh

EXPOSE 143
ENTRYPOINT ["/usr/local/bin/bridge-entrypoint.sh"]
