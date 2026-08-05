FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_pgsql
RUN docker-php-ext-install redis
COPY src/ /var/www/html/
EXPOSE 80