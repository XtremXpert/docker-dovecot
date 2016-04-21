FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y dovecot-common dovecot-imapd dovecot-mysql

ADD dovecot /etc/dovecot
ADD start.sh /start.sh  

RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf

# default config
ENV DB_HOST localhost
ENV DB_USER root 
ENV DB_NAME 
ENV DB_PASSWORD

# IMAP ports  
EXPOSE 143
EXPOSE 993

CMD sh start.sh
