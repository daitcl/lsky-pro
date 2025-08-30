FROM php:8.1-apache

# 如果构建速度慢可以换源
# RUN sed -i -E "s@http://.*.debian.org@http://mirrors.cloud.tencent.com@g" /etc/apt/sources.list

# 安装相关拓展
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# 开启SSL
RUN a2enmod ssl && a2ensite default-ssl

RUN apt-get update && \
    apt-get install -y gettext libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libzip-dev && \
    apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && \
    a2enmod rewrite && chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions imagick bcmath gd pdo_mysql pdo_pgsql redis dom fileinfo intl mbstring zip exif pcntl memcached && \
    \
    # 启用必要的PHP函数
    { \
    echo 'disable_functions = '; \
    } > /usr/local/etc/php/conf.d/enable-functions.ini; \
    \
    # 调整PHP配置
    { \
    echo 'post_max_size = 100M;'; \
    echo 'upload_max_filesize = 100M;'; \
    echo 'max_execution_time = 600;'; \
    echo 'memory_limit = 512M;'; \
    } > /usr/local/etc/php/conf.d/lsky-php.ini; \
    \
    # 配置OPcache
    { \
    echo 'opcache.enable=1'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.revalidate_freq=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    \
    echo 'apc.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini; \
    \
    mkdir /var/www/data; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

# 复制SSL证书
COPY ./ssl /etc/ssl

# 复制本地源码
COPY ./html /var/www/lsky/

# 复制Apache配置模板
COPY ./000-default.conf.template /etc/apache2/sites-enabled/
COPY ./ports.conf.template /etc/apache2/

# 复制入口脚本
COPY entrypoint.sh /
RUN chmod a+x /entrypoint.sh

WORKDIR /var/www/html/
VOLUME /var/www/html
ENV WEB_PORT 8089
ENV HTTPS_PORT 8088
EXPOSE ${WEB_PORT}
EXPOSE ${HTTPS_PORT}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apachectl","-D","FOREGROUND"]