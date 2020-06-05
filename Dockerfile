FROM alpine:latest as basesystem

RUN set -x \
    && apk update \
    && apk upgrade \
    && apk add --update --no-cache alpine-sdk sudo git bash \
    && rm -rf /var/cache/apk/*

FROM basesystem as webbase

# Install packages
RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl nginx supervisor \
    php7 php7-common php7-iconv php7-json php7-gd \
    php7-curl php7-xml php7-pgsql php7-imap php7-cgi \
    fcgi php7-pdo php7-pdo_pgsql php7-soap \
    php7-xmlrpc php7-posix php7-mcrypt \
    php7-gettext php7-ldap php7-ctype php7-dom \
    php7-fpm php7-pdo_pgsql php7-session php7-mysqli  \
    php7-mbstring php7-xml php7-gd php7-zlib php7-bz2 \
    php7-zip php7-openssl php7-opcache php7-pdo_mysql \
    php7-pdo_odbc php7-pecl-apcu \
    && rm -rf /var/cache/apk/*

EXPOSE 9000

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
    chown -R nobody.nobody /run && \
    chown -R nobody.nobody /var/lib/nginx && \
    chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 1010

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:1010/fpm-ping
