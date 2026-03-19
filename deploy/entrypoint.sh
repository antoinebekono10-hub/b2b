#!/usr/bin/env bash
set -euo pipefail

# Assure l'existence des chemins cache/session/views avant le bootstrap Laravel
mkdir -p \
  /app/storage/framework/cache \
  /app/storage/framework/sessions \
  /app/storage/framework/views \
  /app/storage/logs \
  /app/bootstrap/cache

# Assure les permissions runtime
chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Lancer PHP-FPM
php-fpm -D

# Lancer Nginx en foreground
nginx -g 'daemon off;'
