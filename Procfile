web: if [ -f /app/.env ]; then export $(grep -v '^#' /app/.env | xargs); fi; php-fpm -D && nginx -g 'daemon off;'
