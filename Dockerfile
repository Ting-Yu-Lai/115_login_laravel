# syntax=docker/dockerfile:1

# ============================================================
# Stage 1: vendor — 只用 composer.json/composer.lock 安裝 PHP 依賴
#   對應技巧 3（docker-image-slimming）：依賴清單先進去，程式碼還沒進來，
#   之後改 app 程式碼不會讓這層 cache 失效。
# ============================================================
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# ============================================================
# Stage 2: runtime — 精簡的 php-fpm-alpine，只放「成品」
#   對應技巧 1（alpine base）+ 技巧 4（multi-stage，只 COPY --from）
# ============================================================
FROM php:8.2-fpm-alpine AS runtime
WORKDIR /var/www/html

# 技巧 2：安裝 build 用的 -dev 套件、編譯 PHP extension、
# 再刪掉 -dev 套件，全部寫在同一個 RUN 裡，暫存檔才不會殘留在 layer 中。
RUN apk add --no-cache \
        libpng libjpeg-turbo freetype libzip icu-libs \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev icu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql gd zip intl opcache \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 只從 vendor 階段搬「成品」過來，完全不含 Composer 本身這些
# build 期才需要的東西。
COPY --from=vendor /app/vendor ./vendor
COPY . .

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

USER www-data

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
