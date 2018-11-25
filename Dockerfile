#http://devdocs.magento.com/guides/v2.1/install-gde/system-requirements-tech.html
FROM php:7.0-fpm-alpine

MAINTAINER Lukas Beranek <lukas@beecom.io>

ENV REDIS_VERSION 4.0.2

#BUILD dependencies
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev \
    libpng-dev libjpeg-turbo-dev icu-dev libxml2 libxml2-dev libmcrypt-dev \
    libxslt-dev \
    patch \
    git

RUN  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(getconf _NPROCESSORS_ONLN) && \
  docker-php-ext-install -j${NPROC} gd

RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$REDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mkdir -p /usr/src/php/ext \
    && mv phpredis-* /usr/src/php/ext/redis

RUN docker-php-ext-install \
  bcmath \
#  mbstring \ #already loaded
  opcache \
  mysqli \
  pdo_mysql \
  soap \
  zip \
  mcrypt \
  xsl \
  intl \
  redis

#cleanup
RUN apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN curl -sS https://getcomposer.org/installer | \
  php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -O https://files.magerun.net/n98-magerun.phar \
    && chmod +x ./n98-magerun.phar \
    && mv ./n98-magerun.phar /usr/local/bin/magerun

ENV PHP_MEMORY_LIMIT 2G
ENV PHP_PORT 9000
ENV PHP_PM dynamic
ENV PHP_PM_MAX_CHILDREN 10
ENV PHP_PM_START_SERVERS 4
ENV PHP_PM_MIN_SPARE_SERVERS 2
ENV PHP_PM_MAX_SPARE_SERVERS 6


COPY conf/www.conf /usr/local/etc/php-fpm.d/
COPY conf/php.ini /usr/local/etc/php/
COPY conf/php-fpm.conf /usr/local/etc/
COPY bin/* /usr/local/bin/

WORKDIR /var/www/html

RUN ["chmod", "+x", "/usr/local/bin/start"]
