Please read [this page](https://github.com/hardware/mailserver/issues/122) before to acknowledge all the changes between this two versions.

### Backup your docker-compose.yml
   
```bash
cp docker-compose.yml docker-compose.yml.bak
```

### Backup your mail volume (e.g. /mnt/docker/mail)
   
```bash
docker-compose stop mailserver
tar --xattrs -czpPf backup.tar.gz /mnt/docker/mail
```

If a serious problem occurs during update process, you can restore your data with the following command :

```bash
tar --xattrs --numeric-owner -xpPzf backup.tar.gz
```

### Pull the latest image

```bash
# Pull from hub.docker.com
docker pull hardware/mailserver:1.1-stable # Get the stable version (v1.1-stable branch)
docker pull hardware/mailserver:1.1-latest # Get the latest version (master branch)

# or build it manually
docker build -t hardware/mailserver https://github.com/hardware/mailserver.git#v1.1-stable
```

### Update your docker-compose.yml

```yml
version: '2.1'                             # <- New docker-compose file version

mailserver:
    image: hardware/mailserver:1.1-stable  # <- New tag
    container_name: mailserver
    domainname: domain.tld
    hostname: mail
    ports:
      - "25:25"
      - "143:143"
      - "587:587"
      - "993:993"
      - "4190:4190"
    # - "11334:11334"                      # <- New port, not needed if the                         
    environment:                           #    webserver is on the same host
      - DBPASS=xxxxxxx
      - RSPAMD_PASSWORD=xxxxxxx            # <- New required variable
    volumes:
      - /mnt/docker/mail:/var/mail
    depends_on:
      - mariadb
      - redis                              # <- New dependency

redis:		
    image: redis:3.2-alpine		
    container_name: redis		
    command: redis-server --appendonly yes		
    volumes:
      - /mnt/docker/redis/db:/data

nginx:
    depends_on:
      - mailserver                         # <- New dependency
      - postfixadmin
      - rainloop

# Unchanged docker containers : postfixadmin, rainloop, nsd, mariadb
```

**New environment variables**

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **REDIS_HOST** | Redis instance ip/hostname | *optional*  | redis
| **REDIS_PORT** | Redis instance port | *optional*  | 6379
| **REDIS_PASS** | Redis database password | *optional* | null
| **REDIS_NUMB** | Redis database number | *optional* | 0
| **RSPAMD_PASSWORD** | Rspamd WebUI and controller password | **required** | null
| **DISABLE_SIGNING** | Disable DKIM/ARC signing | *optional* | false
| **DISABLE_GREYLISTING** | Disable greylisting policy | *optional* | false
| **DISABLE_RATELIMITING** | Disable ratelimiting policy | *optional* | false
| **DISABLE_RSPAMD_MODULE** | List of disabled modules separated by commas | *optional* | null
| **DISABLE_DNS_RESOLVER** | Disable the local DNS resolver | *optional* | false
| **ENABLE_ENCRYPTION** | Enable automatic GPG encryption | *optional* | false
| **PASSWORD_SCHEME** | Passwords encryption scheme | *optional* | `SHA512-CRYPT`

**Removed environment variables**

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **DISABLE_SPAMASSASSIN** | Disable SPAM checking | *optional* | false
| **GREYLISTING** | Enable greylisting policy server | *optional* | off

**Removed volumes**

- **/etc/opendkim/keys**

:information_source: All DKIM keys are automatically moved to the new location (/var/mail/dkim/domain.tld).

### Clean previous container and start the new one

```bash
docker-compose stop mailserver
docker-compose rm mailserver
docker-compose up -d
```

### Rspamd WebUI : add a new nginx virtual host

:bulb: Don't forget to add a new A/CNAME record in your DNS zone.

```
docker exec -ti nginx ngxproxy

Welcome to ngxproxy utility.
We're about to create a new virtual host (AKA server block).

Name: rspamd
Domain: spam.domain.tld
Webroot (default is /): 
Container: mailserver
Port (default is 80): 11334
HTTPS [y/n]: y
Certificate path: /certs/live/mail.domain.tld/fullchain.pem
Certificate key path: /certs/live/mail.domain.tld/privkey.pem
Secure headers [y/n]: y
Enable HSTS header ? [y/n]: n # Use with caution
Max body size in MB (integer/null): null

Done! rspamd.conf has been generated.
Reload nginx now? [y/n]: y
nginx successfully reloaded.
```

And request a new Let's Encrypt certificate with xataz/letsencrypt or cerbot to add `spam.domain.tld` subdomain :

```bash
docker-compose nginx stop

docker run -it --rm \
  -v /mnt/docker/nginx/certs:/etc/letsencrypt \
  -p 80:80 -p 443:443 \
  xataz/letsencrypt \
    certonly --standalone \
    --rsa-key-size 4096 \
    --agree-tos \
    -m contact@domain.tld \
    -d mail.domain.tld \
    -d webmail.domain.tld \
    -d postfixadmin.domain.tld \
    -d spam.domain.tld

docker-compose up -d
```

Then try to access to Rspamd WebUI with this URL : https://spam.domain.tld 

![](http://i.imgur.com/HIZ5O5X.png)

:tada: It's already done, easy no ? ;-) 

Feel free to give your feedback, improve this new version and make suggestions. And have a wonderfull day with your new mail server :)