## Image multi-étapes pour déploiement sur Railway avec Nginx + PHP-FPM
# syntax=docker/dockerfile:1

##############################
# Étape vendor (composer)
##############################
FROM composer:2 AS vendor
WORKDIR /app
ENV COMPOSER_ALLOW_SUPERUSER=1
# Accepte l'absence de composer.lock (fallback sur composer.json)
COPY composer.json composer.lock* ./
# Platform PHP alignée sur runtime (8.2) + scripts désactivés (artisan non copié à cette étape) + ext-gd ignoré pendant le build vendor (présent en runtime)
RUN composer config --global platform.php 8.2.0 && \
    composer install \
      --no-dev \
      --prefer-dist \
      --no-interaction \
      --no-progress \
      --no-scripts \
      --optimize-autoloader \
      --ignore-platform-req=ext-gd

##############################
# Étape assets (optionnelle)
##############################
FROM node:18-bullseye AS assets
ARG BUILD_ASSETS=false
WORKDIR /app
COPY package.json yarn.lock* ./
# Installe les dépendances uniquement si BUILD_ASSETS=true
RUN if [ "$BUILD_ASSETS" = "true" ]; then \
      if [ -f yarn.lock ]; then corepack enable && yarn install --frozen-lockfile; else npm install; fi; \
    else \
      mkdir -p public/js public/css; \
    fi
COPY resources/ webpack.mix.js ./
RUN if [ "$BUILD_ASSETS" = "true" ]; then \
      if [ -f yarn.lock ]; then yarn production; else npm run production; fi; \
    else \
      mkdir -p public/js public/css; \
    fi

##############################
# Étape finale runtime
##############################
FROM php:8.2-fpm-bullseye

ENV PORT=8080 \
    APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr

# Nginx + dépendances PHP
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nginx git unzip \
      libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install pdo_mysql gd zip bcmath exif && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

WORKDIR /app

# Code applicatif
COPY . /app
COPY --from=vendor /app/vendor /app/vendor
COPY --from=assets /app/public/js /app/public/js
COPY --from=assets /app/public/css /app/public/css

RUN chown -R www-data:www-data storage bootstrap/cache

# Config Nginx & entrypoint
COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/default.conf /etc/nginx/conf.d/default.conf
COPY deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
