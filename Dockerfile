FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y \
        dovecot \
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
    
ADD dovecot /etc/dovecot
ADD startup /startup  

RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf
# default config
ENV DBHOST dbsrv
ENV DBUSER mailuser
ENV DBNAME mailserver
ENV DBPASS Ch4ng3m3

VOLUME /var/mail /var/lib/dovecot /etc/letsencrypt
# IMAP ports  
EXPOSE 143
EXPOSE 993
EXPOSE 4190

CMD sh startup
