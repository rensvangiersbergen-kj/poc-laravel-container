# Stage 1: Build assets
FROM node:18-alpine as frontend-builder

WORKDIR /app

# Copy Laravel app and build assets
COPY . .

RUN npm install && npm run build


# Stage 2: Laravel app with PHP-FPM + Nginx
FROM php:8.2-fpm

# Install system dependencies and clean up after
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    zip \
    unzip \
    gnupg \
    && docker-php-ext-install -j$(nproc) gd ftp zip pcntl \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working dir
WORKDIR /var/www/html

# Copy Laravel app source
COPY . .

# Copy built frontend assets
COPY --from=frontend-builder /app/public ./public

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Use PHP recommended production settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Nginx config
COPY docker/nginx-fpm/nginx.conf /etc/nginx/nginx.conf

# Nginx permissions
RUN mkdir -p /run/nginx && chown -R www-data:www-data /run/nginx
RUN mkdir -p /var/lib/nginx/body && chown -R www-data:www-data /var/lib/nginx && chmod 755 /var/lib/nginx/body

# Supervisor config to run both services
COPY docker/nginx-fpm/supervisord.conf /etc/supervisord.conf

# Ensure correct permissions
RUN chown -R www-data:www-data /var/www
RUN chmod +x docker/nginx-fpm/start.sh

# Switch to the non-privileged user to run the application
USER www-data

EXPOSE 80

CMD ["docker/nginx-fpm/start.sh"]
