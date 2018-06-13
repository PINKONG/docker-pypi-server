FROM python:3-alpine

ENV PYPISERVER_VERSION 0.4.7
ENV PYPISERVER_DEPS 'peewee<3.0' 'tornado<5.0'

RUN set -ex \
 && apk add --no-cache ca-certificates \
 && apk add --no-cache --virtual .build-deps \
    gcc \
    libffi-dev \
    musl-dev \
    openssl-dev \
    libxml2-dev \
    libxslt-dev \
    curl-dev \
 && PYCURL_SSL_LIBRARY=openssl pip install --no-cache-dir pypi-server[proxy]==${PYPISERVER_VERSION} ${PYPISERVER_DEPS} \
 && find /usr/local -depth \
    \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
    -exec rm -rf '{}' + \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
 && apk add --virtual .pypiserver-rundeps $runDeps \
 && apk del .build-deps \
 && rm -rf ~/.cache

RUN mkdir /packages
VOLUME /packages
WORKDIR /packages

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8080

ENV ADDRESS 0.0.0.0
ENV STORAGE /packages
