FROM alpine:3.8

LABEL maintainer="geekdada <me@dada.li>"

ARG TZ='Asia/Shanghai'

ENV TZ $TZ
ENV SS_LIBEV_VERSION 3.2.3
ENV SS_DOWNLOAD_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SS_LIBEV_VERSION}/shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz
ENV OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git

RUN apk upgrade --update \
    && apk add bash tzdata libsodium \
    && apk add --virtual .build-deps \
        autoconf \
        automake \
        xmlto \
        build-base \
        curl \
        c-ares-dev \
        libev-dev \
        libtool \
        linux-headers \
        udns-dev \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        udns-dev \
        tar \
        git \
    && curl -sSLO ${SS_DOWNLOAD_URL} \
    && tar -zxf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
    && (cd shadowsocks-libev-${SS_LIBEV_VERSION} \
    && ./configure --prefix=/usr --disable-documentation \
    && make install) \
    && git clone ${OBFS_DOWNLOAD_URL} \
    && (cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh && ./configure --disable-documentation\
    && make && make install) \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
        )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps \
    && rm -rf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
        shadowsocks-libev-${SS_LIBEV_VERSION} \
        simple-obfs \
        /var/cache/apk/*
