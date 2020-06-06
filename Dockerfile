FROM alpine:latest as basesystem

# Environments
ENV TIMEZONE            America/Sao_Paulo

RUN set -x \
    && apk update \
    && apk upgrade \
    && apk add --update --no-cache \
    tzdata \
    alpine-sdk \
    sudo \
    git \
    bash \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # Cleaning up
    && apk del tzdata  \
    && rm -rf /var/cache/apk/*

FROM basesystem as webbase

# Environments
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M

# Let's roll
# Install packages
RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl nginx supervisor fcgi \
    php7 \
    php7-common \
    php7-iconv \
    php7-json \
    php7-curl \
    php7-xml \
    php7-pgsql \
    php7-imap \
    php7-cgi \
    php7-pdo \
    php7-soap \
    php7-xmlrpc \
    php7-posix \
    php7-mcrypt \
    php7-gettext \
    php7-ldap \
    php7-ctype \
    php7-dom \
    php7-fpm \
    php7-pdo_pgsql \
    php7-session \
    php7-mysqli  \
    php7-mbstring \
    php7-xml \
    php7-gd \
    php7-zlib \
    php7-bz2 \
    php7-zip \
    php7-openssl \
    php7-opcache \
    php7-pdo_mysql \
    php7-pdo_odbc \
    php7-pecl-apcu \
    php7-gmp \
    php7-sqlite3 \
    php7-bcmath \
    php7-pdo_sqlite \
    php7-xmlreader \
    php7-pdo_dblib  \
    # Set environments
    && sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf  \
    && sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = 9000|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;*listen\s*=\s*/||g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini  \
    && sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini  \
    && sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini  \
    && sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini  \
    && sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini \
    && sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini  \
    # Cleaning up
    && apk del tzdata  \
    && rm -rf /var/cache/apk/*

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
# COPY config/php.ini /etc/php7/conf.d/custom.ini

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
# Set Workdir
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose volumes
VOLUME ["/var/www/html"]

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

# Entry point
# ENTRYPOINT ["/usr/sbin/php-fpm7"]