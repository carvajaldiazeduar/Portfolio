FROM php:8.2-cli
RUN apt-get update && apt-get install -y unzip git && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
WORKDIR /app
COPY src/composer.json ./
RUN composer install --no-interaction --prefer-dist
COPY src/ .
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache bootstrap/cache && \
    chmod -R 777 storage bootstrap/cache
EXPOSE 8000
CMD php artisan serve --host=0.0.0.0 --port=8000

