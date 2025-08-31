<h3><div align="center">Lsky Pro Docker 镜像 - 部署指南</div>

---

<div align="center">
  <img src="https://img.shields.io/github/last-commit/daitcl/lsky-pro" alt="最后提交">
  <img src="https://img.shields.io/github/actions/workflow/status/daitcl/lsky-pro/update-docker.yaml" alt="构建状态">
  <a href="https://github.com/daitcl/lsky-pro/blob/main/License">
    <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT许可证">
  </a>
 <a href="https://hub.docker.com/r/daitcl/lsky-pro">
   <img src="https://img.shields.io/docker/pulls/daitcl/lsky-pro" alt="Docker Hub Pulls">
 </a>
  <a href="https://github.com/daitcl/lsky-pro/pkgs/container/lsky-pro">
    <img src="https://img.shields.io/badge/GHCR.io-Package-blue?logo=github" alt="GHCR Package">
  </a>
</div>

这是一个用于快速部署兰空图床(Lsky Pro)的 Docker 镜像，支持多平台架构(amd64/arm64)，包含完整的运行环境和必要的扩展。

## 功能特性

- ✅ 基于官方 PHP 8.1 镜像构建
- ✅ 预装所有必需的 PHP 扩展
- ✅ 支持 MySQL 和 Memcached
- ✅ 集成 NSFWJS 图片审核功能
- ✅ 多平台支持 (amd64/arm64)
- ✅ 自动 SSL 配置
- ✅ 优化的 PHP 配置

## 快速开始

### 1. 下载环境配置文件

```bash
# 下载默认的 .env 配置文件
curl -o .env https://raw.githubusercontent.com/daitcl/lsky-pro/main/.env
```

### 2. 修改环境配置

编辑 `.env` 文件，至少需要修改以下数据库连接信息：

```ini
DB_CONNECTION=mysql
DB_HOST=lskypro_mysql  # 修改为您的 MySQL 容器名称
DB_PORT=3306
DB_DATABASE=lskypro    # 数据库名称
DB_USERNAME=root       # 数据库用户名
DB_PASSWORD=your_password  # 数据库密码
```

### 3. 创建 Docker Compose 文件

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'
services:
  lskypro:
    image: "daitcl/lsky-pro:latest"
    restart: always
    container_name: lskypro
    volumes:
      - "./uploads:/var/www/html/storage/app/uploads"
      - "./thumbnails:/var/www/html/public/thumbnails"
      - "./public-storage:/var/www/html/storage/app/public"
      - "./cache:/var/www/html/storage/framework/cache/data"
      - "./.env:/var/www/html/.env"
    ports:
      - "8089:8089"
      - "8088:8088"
    environment:
      - WEB_PORT=8089
      - HTTPS_PORT=8088
      - TZ=Asia/Shanghai
      - DB_HOST=lskypro_mysql
      - DB_PORT=3306
      - DB_DATABASE=lskypro
      - DB_USERNAME=root
      - DB_PASSWORD=your_password
      - MEMCACHED_HOST=lskypro_memcached
      - MEMCACHED_PORT=11211
      - CACHE_DRIVER=memcached
      - IMAGE_AUDIT_DRIVER=nsfwjs
      - NSFWAUDIT_ENDPOINT=http://lskypro_nsfwjs:5000
      - NSFWAUDIT_FIELD_NAME=url
    depends_on:
      - lskypro_mysql
      - lskypro_memcached
      - lskypro_nsfwjs

  lskypro_mysql:
    image: "mysql:5.7.22"
    restart: always
    container_name: lskypro_mysql
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./mysql/data:/var/lib/mysql"
      - "./mysql/conf:/etc/mysql"
      - "./mysql/log:/var/log/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: your_password
      MYSQL_DATABASE: lskypro
      TZ: Asia/Shanghai

  lskypro_memcached:
    image: "memcached:1.6-alpine"
    container_name: lskypro_memcached
    restart: always

  lskypro_nsfwjs:
    image: "eugencepoi/nsfw_api:latest"
    container_name: lskypro_nsfwjs
    restart: always
    environment:
      PORT: 5000
```

### 4. 创建必要目录

```bash
mkdir -p uploads thumbnails public-storage cache
mkdir -p mysql/data mysql/conf mysql/log
```

### 5. 启动服务

```bash
docker-compose up -d
```

### 6. 生成应用密钥

```bash
# 在宿主机执行 artisan 命令来生成密钥，并自动写入到已挂载的 .env 文件中 （注意容器名为 lskypro）
docker exec lskypro php artisan key:generate
```

### 7. 访问应用

打开浏览器访问 `http://localhost:8089` 完成安装向导。

## 可选服务介绍

### NSFWJS 图片审核服务（可选）

NSFWJS 是一个基于 TensorFlow.js 的图片内容识别库，专门用于检测图片是否包含不适宜工作场所(NSFW)的内容。它可以将图片分类为以下类别：

- **绘画** (Drawing) - 艺术绘画或卡通内容
- **中性** (Neutral) - 普通、安全的内容
- **性感** (Sexy) - 具有挑逗性但不露骨的内容
- **色情** (Porn) - 明确的色情内容
- **变态** (Hentai) - 日本动漫风格的色情内容

**启用方式：**

1. 确保 `lskypro_nsfwjs` 服务在 Docker Compose 中未注释
2. 在 Lsky Pro 容器的环境变量中设置 `IMAGE_AUDIT_DRIVER=nsfwjs`
3. 确保 `NSFWAUDIT_ENDPOINT` 指向正确的 NSFWJS 服务地址

**禁用方式：**

1. 注释掉 Docker Compose 中的 `lskypro_nsfwjs` 服务
2. 注释掉 Lsky Pro 容器环境变量中的图片审核相关配置
3. 或将 `IMAGE_AUDIT_DRIVER` 设置为空或其他值（如 `file`）

**性能考虑：**

- NSFWJS 需要一定的计算资源，可能会影响图片上传速度
- 对于高流量站点，建议使用专业的云服务（如腾讯云或阿里云内容安全）

### Memcached 缓存服务（可选）

Memcached 是一个高性能的分布式内存对象缓存系统，用于加速动态Web应用程序 by减轻数据库负载。

**优势：**

- **高速访问**：数据存储在内存中，读写速度极快
- **减轻数据库压力**：缓存频繁访问的数据，减少数据库查询
- **分布式支持**：可以部署多个实例形成缓存集群
- **简单易用**：简单的键值存储模型，API 简单易用

**启用方式：**

1. 确保 `lskypro_memcached` 服务在 Docker Compose 中未注释
2. 在 Lsky Pro 容器的环境变量中设置 `CACHE_DRIVER=memcached`
3. 确保 `MEMCACHED_HOST` 和 `MEMCACHED_PORT` 指向正确的 Memcached 服务

**禁用方式：**

1. 注释掉 Docker Compose 中的 `lskypro_memcached` 服务
2. 将 `CACHE_DRIVER` 设置为 `file`（文件缓存）或 `redis`（如果使用 Redis）

**使用建议：**

- 对于小型站点，文件缓存(`file`)可能已经足够
- 对于中型站点，Memcached 可以提供更好的性能
- 对于大型站点，考虑使用 Redis 作为缓存驱动

## 环境变量详解

### Lsky Pro 容器环境变量

| 变量名                 | 默认值                     | 说明               |
| :--------------------- | :------------------------- | :----------------- |
| `WEB_PORT`             | 8089                       | HTTP 服务端口      |
| `HTTPS_PORT`           | 8088                       | HTTPS 服务端口     |
| `TZ`                   | Asia/Shanghai              | 时区设置           |
| `DB_HOST`              | lskypro_mysql              | 数据库主机地址     |
| `DB_PORT`              | 3306                       | 数据库端口         |
| `DB_DATABASE`          | lskypro                    | 数据库名称         |
| `DB_USERNAME`          | root                       | 数据库用户名       |
| `DB_PASSWORD`          | your_password              | 数据库密码         |
| `MEMCACHED_HOST`       | lskypro_memcached          | Memcached 主机地址 |
| `MEMCACHED_PORT`       | 11211                      | Memcached 端口     |
| `CACHE_DRIVER`         | memcached                  | 缓存驱动类型       |
| `IMAGE_AUDIT_DRIVER`   | nsfwjs                     | 图片审核驱动       |
| `NSFWAUDIT_ENDPOINT`   | http://lskypro_nsfwjs:5000 | 图片审核端点地址   |
| `NSFWAUDIT_FIELD_NAME` | url                        | 图片审核字段名称   |

### MySQL 容器环境变量

| 变量名                | 默认值        | 说明                |
| :-------------------- | :------------ | :------------------ |
| `MYSQL_ROOT_PASSWORD` | your_password | MySQL root 用户密码 |
| `MYSQL_DATABASE`      | lskypro       | 默认数据库名称      |
| `TZ`                  | Asia/Shanghai | 时区设置            |

### NSFWJS 容器环境变量

| 变量名 | 默认值 | 说明                |
| :----- | :----- | :------------------ |
| `PORT` | 5000   | NSFWJS API 服务端口 |

## 修改容器名后的环境变量调整

如果您修改了 Docker Compose 文件中的容器名称，需要相应调整环境变量：

### 示例：修改 MySQL 容器名

1. 修改 `docker-compose.yml` 中的 MySQL 容器名：

```yaml
lskypro_mysql:
  container_name: my_custom_mysql  # 修改容器名
```

1. 相应修改 Lsky Pro 容器的 `DB_HOST` 环境变量：

```yaml
lskypro:
  environment:
    - DB_HOST=my_custom_mysql  # 更新为新的容器名
```

### 示例：修改 Memcached 容器名

1. 修改 `docker-compose.yml` 中的 Memcached 容器名：

```yaml
lskypro_memcached:
  container_name: my_custom_memcached  # 修改容器名
```

1. 相应修改 Lsky Pro 容器的 `MEMCACHED_HOST` 环境变量：

```yaml
lskypro:
  environment:
    - MEMCACHED_HOST=my_custom_memcached  # 更新为新的容器名
```

### 示例：修改 NSFWJS 容器名

1. 修改 `docker-compose.yml` 中的 NSFWJS 容器名：

```yaml
lskypro_nsfwjs:
  container_name: my_custom_nsfwjs  # 修改容器名
```

1. 相应修改 Lsky Pro 容器的 `NSFWAUDIT_ENDPOINT` 环境变量：

```yaml
lskypro:
  environment:
    - NSFWAUDIT_ENDPOINT=http://my_custom_nsfwjs:5000  # 更新为新的容器名
```

## 数据持久化

所有重要数据都通过卷挂载到宿主机，确保数据安全：

- `./uploads` - 用户上传的文件
- `./thumbnails` - 缩略图缓存
- `./public-storage` - 公开存储文件
- `./cache` - 框架缓存数据
- `./mysql/data` - MySQL 数据文件
- `./mysql/conf` - MySQL 配置文件
- `./mysql/log` - MySQL 日志文件

## 故障排除

### 1. 端口冲突

如果端口 8089 或 8088 已被占用，可以修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8090:8089"  # 修改主机端口
  - "8091:8088"  # 修改主机端口
```

并相应更新 `.env` 文件中的 `APP_URL`：

```ini
APP_URL=http://localhost:8090
```

### 2. 数据库连接失败

检查 MySQL 容器是否正常运行：

```bash
docker logs lskypro_mysql
```

确保 Lsky Pro 容器的 `DB_HOST` 环境变量与 MySQL 容器名称一致。

### 3. 文件权限问题

如果遇到文件权限问题，可以运行：

```bash
docker exec lskypro chown -R www-data:www-data /var/www/html/storage
docker exec lskypro chmod -R 775 /var/www/html/storage
```

## 更新镜像

要更新到最新版本的镜像：

```bash
docker-compose pull
docker-compose up -d
```

## 许可证
本项目采用 [MIT 许可证](License)

---

## 微信公众号
![微信公众号](./img/gzh.jpg)

---

## 赞赏

请我一杯咖啡吧！

![赞赏码](./img/skm.jpg)
