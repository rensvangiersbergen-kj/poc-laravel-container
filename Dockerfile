# Stage 1: Node.js for assets
FROM node:18-alpine AS node-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: PHP & Laravel
FROM php:8.2-fpm-alpine

# Install minimal dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql \
    && apk del --no-cache libxml2-dev

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copy app files
COPY --chown=www:www . /var/www/html
COPY --chown=www:www --from=node-builder /app/public/build /var/www/html/public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Expose the port Laravel runs on
EXPOSE 9000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD php artisan health:check || exit 1
