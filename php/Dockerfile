# syntax=docker/dockerfile:1
# PHP practice image: Apache serving /var/www/html (mounted from ./src at runtime).
FROM php:8.5.12-apache

# Extensions needed to talk to MariaDB (PDO driver + mysqli).
RUN docker-php-ext-install pdo_mysql mysqli
