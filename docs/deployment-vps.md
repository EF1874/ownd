# Ownd VPS 部署指南

本文面向个人使用、个位数用户、尽量零成本的部署方式。推荐使用 Oracle Cloud Always Free VPS，服务器上用 Docker Compose 运行后端 API、PostgreSQL、MinIO、Redis 和 Caddy。

## 1. 准备账号和域名

### 1.1 注册 Oracle Cloud

1. 打开 Oracle Cloud 官网，注册 Free Tier 账号。
2. 注册时区域建议选择新加坡、日本或韩国，国内访问通常比欧美节点更友好。
3. 按页面要求完成邮箱、手机号和信用卡验证。
4. 进入控制台后，创建 Always Free 规格的计算实例。

实例建议：

- 镜像：Ubuntu 22.04 或 24.04
- 形态：Always Free 可用规格
- 登录方式：下载或粘贴 SSH 公钥

### 1.2 准备域名

至少准备一个 API 域名：

```text
api.example.com -> VPS 公网 IP
```

如果要直接访问 MinIO 文件和控制台，再准备两个域名：

```text
files.example.com -> VPS 公网 IP
minio.example.com -> VPS 公网 IP
```

Caddy 会自动申请 HTTPS 证书，所以 DNS 必须先解析到 VPS。

## 2. 打开防火墙端口

### 2.1 Oracle 安全规则

在 Oracle 控制台的虚拟云网络中，给实例所在子网的入站规则放行：

```text
TCP 22
TCP 80
TCP 443
```

不要把 PostgreSQL、Redis、MinIO 的内部端口直接暴露到公网。

### 2.2 Ubuntu 防火墙

SSH 登录服务器后执行：

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

## 3. 安装 Docker

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

退出 SSH 后重新登录，让 Docker 用户组生效。

验证：

```bash
docker version
docker compose version
```

## 4. 上传或拉取后端代码

当前 `ownd-api` 本地没有配置远程仓库。推荐先把 `ownd-api` 推到一个私有 Git 仓库，然后在 VPS 拉取：

```bash
git clone <你的 ownd-api 仓库地址> ownd-api
cd ownd-api
```

如果暂时不想建仓库，也可以用 `scp` 上传整个 `ownd-api` 目录。

## 5. 配置生产环境变量

在 VPS 的 `ownd-api` 目录执行：

```bash
cp .env.example .env.production
nano .env.production
```

至少修改这些值：

```env
API_DOMAIN=api.example.com
CORS_ORIGIN=https://api.example.com

POSTGRES_USER=ownd
POSTGRES_PASSWORD=换成强密码
POSTGRES_DB=ownd
DATABASE_URL=postgresql://ownd:换成强密码@postgres:5432/ownd?schema=public

JWT_SECRET=换成很长的随机字符串

MINIO_DOMAIN=files.example.com
MINIO_CONSOLE_DOMAIN=minio.example.com
MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_USE_SSL=false
MINIO_BUCKET=ownd-items
MINIO_ROOT_USER=换成强用户名
MINIO_ROOT_PASSWORD=换成强密码
```

生成随机密钥示例：

```bash
openssl rand -base64 48
```

## 6. 启动服务

```bash
docker compose --env-file .env.production -f docker-compose.prod.yaml up -d --build
```

查看状态：

```bash
docker compose --env-file .env.production -f docker-compose.prod.yaml ps
docker compose --env-file .env.production -f docker-compose.prod.yaml logs -f api caddy
```

第一次启动时，API 容器会自动执行：

```bash
prisma migrate deploy
node dist/main
```

## 7. 验证后端

```bash
curl https://api.example.com/api/v1
```

Swagger 文档：

```text
https://api.example.com/api-docs
```

MinIO 控制台：

```text
https://minio.example.com
```

## 8. 更新 Flutter 生产接口地址

修改 `ownd-app/config/prod.json`：

```json
{
    "OWND_API_BASE_URL": "https://api.example.com/api/v1"
}
```

构建 Android 生产包：

```bash
cd ownd-app
pnpm run android:prod
```

## 9. 日常运维命令

更新代码后重新部署：

```bash
git pull
docker compose --env-file .env.production -f docker-compose.prod.yaml up -d --build
```

查看日志：

```bash
docker compose --env-file .env.production -f docker-compose.prod.yaml logs -f api
```

重启服务：

```bash
docker compose --env-file .env.production -f docker-compose.prod.yaml restart api
```

停止服务：

```bash
docker compose --env-file .env.production -f docker-compose.prod.yaml down
```

## 10. 备份建议

个人项目也建议定期备份 PostgreSQL 和 MinIO 数据。

PostgreSQL 备份：

```bash
docker exec ownd-postgres pg_dump -U ownd ownd > ownd-backup.sql
```

MinIO 数据在 Docker volume `minio_data` 中。迁移 VPS 前，先完整备份 Docker volumes。

## 11. 注意事项

- Oracle 免费 VPS 注册可能需要信用卡验证，不代表一定扣费。
- 不要开放 `5432`、`6379`、`9000` 到公网，统一通过 Caddy 暴露 HTTPS。
- `config/prod.json` 里的 API 域名变更后，需要重新打包 App。
- 当前 Android release 仍使用 debug 签名，后续正式分发前应补 Android release keystore。
