#!/usr/bin/env bash
set -euo pipefail

# Assure les permissions runtime
chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Lancer PHP-FPM
php-fpm -D

# Lancer Nginx en foreground
nginx -g 'daemon off;'
