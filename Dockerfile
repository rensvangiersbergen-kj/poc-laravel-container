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
    && docker-php-ext-install pdo_mysql

# Copy app files
COPY --chown=www:www . /var/www/html
COPY --chown=www:www --from=node-builder /app/public/build /var/www/html/public/build

# Install Composer & run install
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Port is already exposed thanks to fpm-alpine by default, uncomment to expose other ports
# EXPOSE 9000

# CMD is already included in fpm-alpine to run the php-fpm server by default
