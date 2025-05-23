#!/bin/sh
if [ ! "$(ls -A /var/www/html/storage)" ]; then
  echo "Initializing storage directory..."
  cp -R /var/www/html/storage-init/. /var/www/html/storage
  chown -R www-data:www-data /var/www/html/storage
fi

php artisan config:clear
php artisan cache:clear

exec /usr/bin/supervisord -c /etc/supervisord.conf
