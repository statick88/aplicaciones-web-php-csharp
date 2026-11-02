# syntax=docker/dockerfile:1
# PHP practice image: Apache serving /var/www/html/public, while the whole
# project is mounted at /var/www/html so entry pages can require
# ../src, ../views and ../config (official Week 1 structure).
FROM php:8.5.12-apache

# Extensions needed to talk to MariaDB (PDO driver + mysqli).
RUN docker-php-ext-install pdo_mysql mysqli

# Only public/ is web-exposed: config/, src/ and views/ stay outside the URL space.
RUN sed -ri 's!DocumentRoot /var/www/html$!DocumentRoot /var/www/html/public!' \
    /etc/apache2/sites-available/000-default.conf \
    && grep -q 'DocumentRoot /var/www/html/public' /etc/apache2/sites-available/000-default.conf
