FROM ubuntu:latest

# default config
ENV DBHOST=dbsrv \
    DBUSER=mailuser \
    DBNAME=mailserver \
    DBPASS=Ch4ng3m3

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update \
    && apt-get install -y \
        dovecot-antispam \
        dovecot-common \
        dovecot-imapd \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-mysql \
        dovecot-sieve \
        python-pip \
        spamc \
    && pip install envtpl
    
COPY dovecot /etc/dovecot
COPY bin /usr/local/bin  

RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf

VOLUME /var/mail /var/lib/dovecot /etc/letsencrypt
# IMAP ports  
EXPOSE 143 993 4190

CMD sh /usr/local/bin/startup.sh
