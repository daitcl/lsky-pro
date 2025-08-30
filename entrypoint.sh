#!/bin/bash
set -eu

WEB_PORT=${WEB_PORT:-8089}
HTTPS_PORT=${HTTPS_PORT:-8088}

envsubst '${WEB_PORT} ${HTTPS_PORT}' < /etc/apache2/sites-enabled/000-default.conf.template > /etc/apache2/sites-enabled/000-default.conf
envsubst '${WEB_PORT} ${HTTPS_PORT}' < /etc/apache2/ports.conf.template > /etc/apache2/ports.conf

# 初始化Lsky Pro应用
if [ ! -e '/var/www/html/public/index.php' ]; then
    cp -a /var/www/lsky/* /var/www/html/
    cp -a /var/www/lsky/.env.example /var/www/html/
    
    # 如果源码中已有vendor目录，则不需要重新安装
    if [ ! -d '/var/www/html/vendor' ]; then
        echo "Installing Composer dependencies..."
        cd /var/www/html && composer install --no-dev --optimize-autoloader
    fi
    
    # 设置存储目录权限
    if [ -d '/var/www/html/storage' ]; then
        chmod -R 775 /var/www/html/storage/
        chown -R www-data:www-data /var/www/html/storage/
    fi
    
    if [ -d '/var/www/html/bootstrap/cache' ]; then
        chmod -R 775 /var/www/html/bootstrap/cache/
        chown -R www-data:www-data /var/www/html/bootstrap/cache/
    fi
fi

# 设置文件权限
chown -R www-data:www-data /var/www/html/
find /var/www/html -type f -exec chmod 644 {} \;
find /var/www/html -type d -exec chmod 755 {} \;

# 如果.env不存在，从示例创建
if [ ! -f '/var/www/html/.env' ] && [ -f '/var/www/html/.env.example' ]; then
    cp /var/www/html/.env.example /var/www/html/.env
    
    # 配置NsfwJS图片审核
    sed -i "s/^IMAGE_AUDIT_DRIVER=.*/IMAGE_AUDIT_DRIVER=nsfwjs/" /var/www/html/.env
    sed -i "s|^NSFWAUDIT_ENDPOINT=.*|NSFWAUDIT_ENDPOINT=http://nsfwjs:5000|" /var/www/html/.env
    sed -i "s/^NSFWAUDIT_FIELD_NAME=.*/NSFWAUDIT_FIELD_NAME=url/" /var/www/html/.env
    
    # 生成应用密钥
    php /var/www/html/artisan key:generate
    
    echo "Environment file created from example."
fi

# 更新配置（如果环境变量已设置）
if [ -f '/var/www/html/.env' ]; then
    # 更新数据库配置（如果环境变量已设置）
    if [ ! -z "${DB_HOST:-}" ]; then
        sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" /var/www/html/.env
    fi
    if [ ! -z "${DB_PORT:-}" ]; then
        sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" /var/www/html/.env
    fi
    if [ ! -z "${DB_DATABASE:-}" ]; then
        sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" /var/www/html/.env
    fi
    if [ ! -z "${DB_USERNAME:-}" ]; then
        sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" /var/www/html/.env
    fi
    if [ ! -z "${DB_PASSWORD:-}" ]; then
        sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" /var/www/html/.env
    fi
    
    # 更新Memcached配置（如果环境变量已设置）
    if [ ! -z "${MEMCACHED_HOST:-}" ]; then
        sed -i "s/^MEMCACHED_HOST=.*/MEMCACHED_HOST=${MEMCACHED_HOST}/" /var/www/html/.env
    fi
    if [ ! -z "${MEMCACHED_PORT:-}" ]; then
        # 检查MEMCACHED_PORT配置是否存在，不存在则添加
        if ! grep -q "^MEMCACHED_PORT=" /var/www/html/.env; then
            echo "MEMCACHED_PORT=${MEMCACHED_PORT}" >> /var/www/html/.env
        else
            sed -i "s/^MEMCACHED_PORT=.*/MEMCACHED_PORT=${MEMCACHED_PORT}/" /var/www/html/.env
        fi
    fi
    
    # 更新缓存驱动（如果环境变量已设置）
    if [ ! -z "${CACHE_DRIVER:-}" ]; then
        sed -i "s/^CACHE_DRIVER=.*/CACHE_DRIVER=${CACHE_DRIVER}/" /var/www/html/.env
    fi
    
    # 更新图片审核配置（如果环境变量已设置）
    if [ ! -z "${IMAGE_AUDIT_DRIVER:-}" ]; then
        sed -i "s/^IMAGE_AUDIT_DRIVER=.*/IMAGE_AUDIT_DRIVER=${IMAGE_AUDIT_DRIVER}/" /var/www/html/.env
    fi
    
    if [ ! -z "${NSFWAUDIT_ENDPOINT:-}" ]; then
        if ! grep -q "^NSFWAUDIT_ENDPOINT=" /var/www/html/.env; then
            echo "NSFWAUDIT_ENDPOINT=${NSFWAUDIT_ENDPOINT}" >> /var/www/html/.env
        else
            sed -i "s|^NSFWAUDIT_ENDPOINT=.*|NSFWAUDIT_ENDPOINT=${NSFWAUDIT_ENDPOINT}|" /var/www/html/.env
        fi
    fi
    
    if [ ! -z "${NSFWAUDIT_FIELD_NAME:-}" ]; then
        if ! grep -q "^NSFWAUDIT_FIELD_NAME=" /var/www/html/.env; then
            echo "NSFWAUDIT_FIELD_NAME=${NSFWAUDIT_FIELD_NAME}" >> /var/www/html/.env
        else
            sed -i "s|^NSFWAUDIT_FIELD_NAME=.*|NSFWAUDIT_FIELD_NAME=${NSFWAUDIT_FIELD_NAME}|" /var/www/html/.env
        fi
    fi
fi

exec "$@"