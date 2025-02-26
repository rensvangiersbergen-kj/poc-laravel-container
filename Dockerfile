# Stage 1: Node.js for assets
FROM node:18-alpine as node-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: PHP & Laravel
FROM php:8.2-fpm-alpine

# Install dependencies and clean up in a single layer
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
    && docker-php-ext-install gd pdo pdo_mysql pdo_sqlite \
    # Remove build dependencies
    && apk del --no-cache \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libxml2-dev
    
# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Create non-root user
RUN addgroup -S www && adduser -S www -G www

# Set working directory
WORKDIR /var/www

# Copy app files
COPY --chown=www:www . /var/www/
COPY --chown=www:www --from=node-builder /app/public/build /var/www/public/build

# Create storage directory structure and set permissions
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && chown -R www:www storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Install PHP dependencies as non-root user
USER www
RUN composer install --no-dev --optimize-autoloader

# Expose the port Laravel runs on
EXPOSE 9000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/health || exit 1
