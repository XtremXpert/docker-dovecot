# Dovecot imap servers inside Docker

This docker container is aimed to run Dovecot in Docker as imap server.
You can receive and manage emails using Dovecot server.

To create email addresses you need MySQL database with [tables](https://github.com/Codegyre/DockerPostfixDovecot/blob/master/mailschema.sql); add email domains into `mail_virtual_domains`, add email users to `mail_virtual_users`. 

### Environment Vars

* **APP_HOST** (required)- email server host
* **DB_NAME** (required) - database
* **DB_USER** (root) - user to access mysql database
* **DB_PASSWORD** - mysql user password

### Directories

* `/home/vmail/:/home/vmail/` - directory to store emails
