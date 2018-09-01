FROM nginx:1.15.3-alpine as builder

RUN apk add --no-cache --virtual .build-deps \
      curl \
      gcc \
      gd-dev \
      geoip-dev \
      gnupg \
      libc-dev \
      libxslt-dev \
      linux-headers \
      make \
      openldap-dev \
      pcre-dev \
      tar \
      unzip \
      zlib-dev 
RUN mkdir -p /tmp/src
RUN curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz
RUN tar -zxC /tmp/src -f nginx.tar.gz
RUN curl -fsSL https://github.com/kvspb/nginx-auth-ldap/archive/master.zip -o /tmp/nginx-auth-ldap-master.zip
RUN unzip -d /tmp/src /tmp/nginx-auth-ldap-master.zip
WORKDIR /tmp/src/nginx-$NGINX_VERSION

RUN ./configure --with-http_ssl_module --with-compat --add-dynamic-module=/tmp/src/nginx-auth-ldap-master
RUN make modules


FROM nginx:1.15.3-alpine as production
RUN apk add --no-cache libldap 
COPY --from=builder /tmp/src/nginx-$NGINX_VERSION/objs/ngx_http_auth_ldap_module.so /usr/lib/nginx/modules/ngx_http_auth_ldap_module.so
RUN sed -i '1i load_module "/usr/lib/nginx/modules/ngx_http_auth_ldap_module.so";' /etc/nginx/nginx.conf
RUN sed -i '16i include /etc/nginx/ldap.conf;' /etc/nginx/nginx.conf
RUN rm -fr \
    /etc/nginx/*.default \
    /tmp/* \
    /var/tmp/* \
    /var/cache/apk/*
