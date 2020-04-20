FROM debian:buster-slim
LABEL description "Simple and full-featured mail server using Docker" \
      maintainer="datoma - https://github.com/datoma"

ARG DEBIAN_FRONTEND=noninteractive
ARG CODENAME="buster"
ARG SKALIBS_VER=2.9.2.1
ARG SKALIBS_SHA256_HASH="250b99b53dd413172db944b31c1b930aa145ac79fe6c5d7e6869ef804228c539"
ARG EXECLINE_VER=2.6.0.1
ARG EXECLINE_SHA256_HASH="e7cbb7b5942674a0b5176c42aa0a3194a848419a698e4aad9d1764d2b429ba9d"
ARG S6_VER=2.9.1.0
ARG S6_SHA256_HASH="05e259532c6db8cb23f5f79938669cee30152008ac9e792ff4acb26db9a01ff7"

RUN apt-get update && apt-get install -y -q lsb-release wget curl gnupg2 \
 && curl -sL https://rspamd.com/apt-stable/gpg.key | apt-key add - \
 && echo "deb http://rspamd.com/apt-stable/ ${CODENAME} main" > /etc/apt/sources.list.d/rspamd.list \
 && apt-get update && apt-get --no-install-recommends install -y -q rspamd \
    postfix postfix-pgsql postfix-mysql postfix-ldap postfix-pcre libsasl2-modules \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pgsql dovecot-mysql dovecot-ldap dovecot-sieve dovecot-managesieved dovecot-pop3d \
    fetchmail libdbi-perl libdbd-pg-perl libdbd-mysql-perl liblockfile-simple-perl \
    clamav clamav-daemon \
    python3-pip python3-setuptools python3-wheel \
    rsyslog dnsutils curl unbound jq rsync \
    cmake gcc make ragel pkg-config liblua5.1-0-dev libluajit-5.1-dev libglib2.0-dev libevent-dev libsqlite3-dev libicu-dev libssl-dev libhyperscan-dev libjemalloc-dev libmagic-dev \
    inotify-tools \
 && rm -rf /var/spool/postfix \
 && ln -s /var/mail/postfix/spool /var/spool/postfix \
 && apt-get update && apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libevent-2.1-6 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
    libluajit-5.1-2 \
    libsqlite3-0 \
    libhyperscan5 \
    libjemalloc2 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
    netcat \
 && cd /tmp \
 && SKALIBS_TARBALL="skalibs-${SKALIBS_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/skalibs/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install \
 && cd /tmp \
 && EXECLINE_TARBALL="execline-${EXECLINE_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/execline/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr \
 && make && make install \
 && cd /tmp \
 && S6_TARBALL="s6-${S6_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/s6/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install \
 && pip3 install watchdog \
 && apt-get remove -y make cmake gcc ragel pkg-config liblua5.1-0-dev libluajit-5.1-dev libglib2.0-dev libevent-dev libsqlite3-dev libicu-dev libssl-dev libhyperscan-dev libjemalloc-dev libmagic-dev \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old

EXPOSE 25 143 465 587 993 4190 11334
COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish
CMD ["run.sh"]
