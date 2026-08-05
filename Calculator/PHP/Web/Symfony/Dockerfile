FROM php:8.2-cli
RUN apt-get update && apt-get install -y unzip git && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
WORKDIR /app
COPY src/composer.json ./
RUN composer install --no-interaction --prefer-dist
COPY src/ .
EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]


