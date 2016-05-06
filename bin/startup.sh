#!/bin/bash

# ENV
export FQDN
export DOMAIN
export VMAILUID
export VMAILGID
export DBHOST
export DBNAME
export DBUSER
export CAFILE
export CERTFILE
export KEYFILE
export FULLCHAIN

FQDN=$(hostname --fqdn)
DOMAIN=$(hostname --domain)
VMAILUID=${VMAILUID:-5000}
VMAILGID=${VMAILGID:-5000}
DBHOST=${DBHOST:-dbsrv}
DBNAME=${DBNAME:-mailserveruser}
DBUSER=${DBUSER:-mailserver}

ADD_DOMAINS=${ADD_DOMAINS:-}

if [ -z "$DBPASS" ]; then
  echo "Mariadb database password must be set !"
  exit 1
fi
# SSL certificates
LETS_ENCRYPT_LIVE_PATH=/etc/letsencrypt/live/"$FQDN"

if [ -d "$LETS_ENCRYPT_LIVE_PATH" ]; then
  FULLCHAIN="$LETS_ENCRYPT_LIVE_PATH"/fullchain.pem
  CAFILE="$LETS_ENCRYPT_LIVE_PATH"/chain.pem
  CERTFILE="$LETS_ENCRYPT_LIVE_PATH"/cert.pem
  KEYFILE="$LETS_ENCRYPT_LIVE_PATH"/privkey.pem
  
#When using https://github.com/JrCs/docker-nginx-proxy-letsencrypt
  # and https://github.com/jwilder/nginx-proxy there is only key.pem and fullchain.pem
  # so we look for key.pem and extract cert.pem and chain.pem

  if [ ! -e "$KEYFILE" ]; then
    KEYFILE="$LETS_ENCRYPT_LIVE_PATH"/key.pem
  fi

  if [ ! -e "$KEYFILE" ]; then
    echo "No keyfile found in $LETS_ENCRYPT_LIVE_PATH !"
    exit 1
  fi

  if [ ! -e "$CAFILE" ] || [ ! -e "$CERTFILE" ]; then
    if [ ! -e "$FULLCHAIN" ]; then
      echo "No fullchain found in $LETS_ENCRYPT_LIVE_PATH !"
      exit
    fi

    awk -v path="$LETS_ENCRYPT_LIVE_PATH" 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > path"/cert" c ".pem"}' < "$FULLCHAIN"
    mv "$LETS_ENCRYPT_LIVE_PATH"/cert1.pem "$CERTFILE"
    mv "$LETS_ENCRYPT_LIVE_PATH"/cert2.pem "$CAFILE"
  fi

else
  FULLCHAIN=/var/mail/ssl/selfsigned/cert.pem
  CAFILE=
  CERTFILE=/var/mail/ssl/selfsigned/cert.pem
  KEYFILE=/var/mail/ssl/selfsigned/privkey.pem

  if [ ! -e "$CERTFILE" ] || [ ! -e "$KEYFILE" ]; then
    mkdir -p /var/mail/ssl/selfsigned/
    openssl req -new -newkey rsa:4096 -days 3658 -sha256 -nodes -x509 \
      -subj "/C=FR/ST=France/L=Paris/O=Mailserver certificate/OU=Mail/CN=*.${DOMAIN}/emailAddress=admin@${DOMAIN}" \
      -keyout "$KEYFILE" \
      -out "$CERTFILE"
  fi
fi

# Diffie-Hellman parameters
if [ ! -e /var/mail/ssl/dhparams/dh2048.pem ] || [ ! -e /var/mail/ssl/dhparams/dh512.pem ]; then
  mkdir -p /var/mail/ssl/dhparams/
  openssl dhparam -out /var/mail/ssl/dhparams/dh2048.pem 2048
  openssl dhparam -out /var/mail/ssl/dhparams/dh512.pem 512
fi

# Add ENV DOMAIN and ADD_DOMAINS
###
#
#
domains=(${DOMAIN})
domains+=(${ADD_DOMAINS//,/ })

for domain in "${domains[@]}"; do
  # Add vhost
  mkdir -p /var/mail/vhosts/"$domain"

done

if [ ! -d "$LETS_ENCRYPT_LIVE_PATH" ]; then
  sed -i '/^\(smtp_tls_CAfile\|smtpd_tls_CAfile\)/s/^/#/' /etc/postfix/main.cf
fi

# Replace {{ ENV }} vars
_envtpl() {
  mv "$1" "$1.tpl" # envtpl requires files to have .tpl extension
  envtpl "$1.tpl"
}

_envtpl /etc/dovecot/conf.d/10-mail.conf
_envtpl /etc/dovecot/dovecot-sql.conf.ext
_envtpl /etc/dovecot/conf.d/10-ssl.conf
_envtpl /etc/dovecot/conf.d/20-lmtp.conf
_envtpl /etc/mailname

# Folders and permissions
groupadd -g "$VMAILGID" vmail
useradd -g vmail -u "$VMAILUID" vmail -d /var/mail
chown -R vmail:vmail /var/mail
chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot
mkdir -p /var/run/dovecot
chown -R dovecot:dovecot /var/run/dovecot

# Sieve
mkdir -p /var/mail/sieve

if [ ! -e /var/mail/sieve/default.sieve ]; then
  cat > /var/mail/sieve/default.sieve <<EOF
require ["fileinto"];
if header :contains "X-Spam-Flag" "YES" {
  fileinto "Spam";
}
EOF
fi

chown -R vmail:vmail /var/mail/sieve
sievec /var/mail/sieve/default.sieve

# Dovecot mountpoints ignoring
doveadm mount add /var/lib/dovecot ignore
doveadm mount add /etc/opendkim/keys ignore
doveadm mount add /etc/letsencrypt ignore

/usr/sbin/dovecot -c /etc/dovecot/dovecot.conf -F
