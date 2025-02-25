# Stage 1: Node.js for assets
FROM node:18-alpine as node-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: PHP & Laravel
FROM php:8.2-fpm-alpine

# Install dependencies in a single layer
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    zip \
    unzip \
    sqlite-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_sqlite 
    
# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Create a user (only once, no switching)
RUN addgroup -S www && adduser -S www -G www

# Set working directory
WORKDIR /var/www

# Copy app files in one step
COPY . /var/www/
COPY --from=node-builder /app/public/build /var/www/public/build

# Set permissions (only once)
RUN chown -R www:www /var/www

# Install PHP dependencies as non-root user
USER www
RUN composer install --no-dev --optimize-autoloader

# Switch back to root
USER root

# Expose ports
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm", "-F"]
