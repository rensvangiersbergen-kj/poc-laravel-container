# Build stage
# Start PHP-FPM server
FROM php:8.2-fpm-alpine

# Set environment variables for user
ARG user=develop
ARG uid=1000

# Install required packages
RUN apk update && apk add --no-cache \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    zip \
    unzip \
    shadow \
    supervisor \
    nginx \
    nodejs \
    npm \
    sqlite-dev \
    redis \
    oniguruma-dev \
    autoconf \
    g++ \
    make \
    gcc

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd bcmath exif pdo pdo_mysql pdo_sqlite

# Install Redis extension for PHP
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Set up a non-root user
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Copy application files
COPY . /var/www/
RUN chown -R $user:$user /var/www

# Switch to non-root user
USER $user

# Install PHP dependencies
RUN composer install --no-interaction --no-scripts

# Install and build Node dependencies
RUN npm ci && npm run build

# Switch back to root for final operations
USER root

# Set working directory
WORKDIR /var/www

# Expose necessary ports
EXPOSE 9000

# Start services
CMD ["php-fpm", "-F"]