# syntax=docker/dockerfile:1

# ============================================================
# development target — 本地開發用，跟下面的 production 完全不同取捨：
#   base 用完整版 php:8.2-fpm（Debian，非 alpine），保留 git/vim/curl，
#   方便 docker exec 進去看狀況；裝 Xdebug 供 step debug；
#   composer install 不加 --no-dev，開發工具（pail、pint、phpunit...）留著；
#   程式碼實際上靠 docker-compose 的 volume mount 進來，
#   下面的 COPY . . 只是讓 image 在還沒掛 volume 前也能開機的 fallback。
#   本機另外還跑著別的專案（102_oa_laravel）的容器，佔用了
#   3308/8080/8088/9443/27017 這幾個 port，這裡刻意不要碰到。
# ============================================================
FROM php:8.2-fpm AS development
WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip curl vim \
        libpng-dev libjpeg62-turbo-dev libfreetype6-dev libzip-dev libicu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install pdo_mysql gd zip intl opcache \
    && pecl install xdebug && docker-php-ext-enable xdebug \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 先裝依賴、含 dev 套件，故意不清 composer/apt cache——
# 開發階段重複 rebuild 的頻率遠高於一次性的 image 大小考量。
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-interaction
COPY . .

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]

# ============================================================
# Stage 1: vendor — 只用 composer.json/composer.lock 安裝 PHP 依賴
#   對應技巧 3（docker-image-slimming）：依賴清單先進去，程式碼還沒進來，
#   之後改 app 程式碼不會讓這層 cache 失效。
#   底層用 php:8.2-cli-alpine（跟 runtime stage 同一個 PHP 版本），
#   只從官方 composer image 借用 composer 執行檔本身——
#   composer:2 image 自己聲明「不要依賴我們容器裡的 PHP 版本」
#   (https://hub.docker.com/_/composer)，它的 PHP 版本會浮動，
#   跟專案實際要跑的 8.2 對不上時，套件相容性檢查就會炸掉。
# ============================================================
FROM php:8.2-cli-alpine AS vendor
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
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
