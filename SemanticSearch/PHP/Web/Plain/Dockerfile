FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_pgsql
COPY src/ /var/www/html/
EXPOSE 80