# Build stage
FROM php:8.2-fpm-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    unzip \
    git \
    composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first
COPY composer.json composer.lock ./

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy application files
COPY . .

# Generate key and optimize
RUN php artisan key:generate && \
    php artisan optimize

# Production stage
FROM php:8.2-fpm-alpine

# Install production dependencies only
RUN apk add --no-cache \
    php-pdo \
    php-pdo_sqlite \
    php-mbstring \
    php-tokenizer \
    php-xml \
    php-curl \
    php-zip \
    php-bcmath \
    php-dom \
    php-fileinfo \
    php-openssl \
    php-sqlite3 \
    sqlite \
    curl

# Set working directory
WORKDIR /var/www/html

# Copy application files from builder
COPY --from=builder /var/www/html /var/www/html

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:9000/ || exit 1

# Expose the PHP port
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm", "-F"]