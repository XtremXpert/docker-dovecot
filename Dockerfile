FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y \
        dovecot-common \
        dovecot-imapd \
        dovecot-mysql \
        dovecot-lmtpd \
        dovecot-sieve \
        dovecot-managesieved \
        dovecot-antispam \
        spamc

ADD dovecot /etc/dovecot
ADD start.sh /start.sh  

RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf

# default config
ENV DB_HOST dbsrv
ENV DB_USER mailuser
ENV DB_NAME mailserver
ENV DB_PASSWORD Ch4ng3m3

# IMAP ports  
EXPOSE 143
EXPOSE 993

CMD sh start.sh
