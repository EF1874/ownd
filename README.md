<p align="center">
  <img src="ownd-app/assets/icon.png" width="120" alt="Ownd Logo" />
</p>

<h1 align="center">Ownd — 物记</h1>
<p align="center">
  <b>个人数字资产管理平台</b><br/>
  追踪你拥有的每一件物品、订阅和数字资产
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## ✨ 功能亮点

- 📦 **物品全生命周期管理** — 记录购买、使用、转手、退役的完整历史
- 📊 **资产统计看板** — TCO 总拥有成本、日均持有支出等实时数据分析
- 🏷️ **分类与平台标签** — 自定义分类体系，追踪购买渠道与平台
- 🔒 **安全认证** — JWT 令牌 + Redis 黑名单机制
- ☁️ **云端同步** — MinIO 对象存储，支持图片上传与备份
- 🚀 **一键部署** — Docker Compose 生产环境一键启动
- 📝 **个人博客** — 集成 Halo 博客系统，通过 `blog.ownd.cc` 访问

---

## 🏗️ 技术架构

| 层级 | 技术栈 |
|------|--------|
| **移动端** | Flutter 3.41 · Dart · Riverpod · Isar |
| **后端 API** | NestJS 11 · TypeScript · Prisma ORM |
| **数据库** | PostgreSQL 16 · Redis 7 |
| **对象存储** | MinIO (S3 兼容) |
| **反向代理** | Caddy 2 (自动 HTTPS) |
| **博客** | Halo 2.20 |
| **CI/CD** | GitHub Actions |

---

## 📂 项目目录结构

本项目采用 **单体大仓 (Monorepo)** 架构，前后端代码统一管理：

```text
ownd/
├── .github/workflows/          # CI/CD 自动化流水线
│   ├── deploy-backend.yml      #   后端自动部署到云服务器
│   └── release-app.yml         #   App 自动编译打包并发布 Release
├── ownd-api/                   # 后端 NestJS 项目
│   ├── src/                    #   业务源码 (auth, items, categories, etc.)
│   ├── prisma/                 #   数据库 Schema 与迁移文件
│   ├── deploy/                 #   Caddy 反向代理配置
│   ├── docker-compose.yaml     #   本地开发容器编排
│   └── docker-compose.prod.yaml#   生产环境容器编排
├── ownd-app/                   # 前端 Flutter 移动端项目
│   ├── lib/                    #   Dart 业务源码
│   ├── android/                #   Android 原生配置
│   ├── ios/                    #   iOS 原生配置
│   └── config/                 #   环境配置 (dev.json / prod.json)
└── README.md
```

---

## 🚀 快速开始

### 克隆项目

```bash
git clone https://github.com/EF1874/ownd.git
cd ownd
```

### 后端开发 (ownd-api)

```bash
cd ownd-api
pnpm install                       # 安装依赖
cp .env.example .env.development   # 配置本地环境变量
docker compose up -d               # 启动 PostgreSQL / Redis / MinIO
npx prisma migrate dev             # 初始化数据库
npx prisma generate                # 生成 Prisma Client
pnpm run start:dev                 # 启动开发服务器
```

### 移动端开发 (ownd-app)

#### 1. 本地局域网联调 (推荐)
后端服务启动时会自动生成含有电脑当前局域网 IP 的配置文件 `ownd-app/config/local.json`。
* **命令行一键安装运行**：
  ```bash
  cd ownd-app
  pnpm android:dev:install
  ```
* **VS Code 一键调试**：
  直接按 **F5**，选择 `物记 (Local IP Debug)` 配置启动调试。

#### 2. 手动指定 API 调试
```bash
cd ownd-app
flutter pub get
flutter run --dart-define=OWND_API_BASE_URL="http://localhost:3000/api/v1"
```

连接线上 API 进行调试：
```bash
flutter run --dart-define=OWND_API_BASE_URL="https://api.ownd.cc/api/v1"
```

---

## 🌐 自动化部署 (CI/CD)

| 流水线 | 触发条件 | 功能 |
|--------|----------|------|
| **Deploy Backend** | 推送 `ownd-api/**` 到 `master` | SSH 登录云服务器，`git pull` 并 `docker compose up --build` |
| **Release App** | 修改 `ownd-app/pubspec.yaml` 版本号 | 编译 Android Release APK，自动创建 GitHub Release |

### 🔑 App 签名与打包说明
* **GitHub Release 正式包**：在 GitHub Actions 流水线中，系统会使用安全的 Secrets 自动解密并使用生产证书（Keystore）进行签名。当你想使用正式签名版时，只需**修改 `ownd-app/pubspec.yaml` 中的版本号**并推送到 `master` 分支，流水线将自动运行并将打包好的 APK 放到 GitHub Release 页，您可直接下载安装。
* **本地打包回退**：如果在本地运行打包命令（如 `pnpm run android:prod`）且未配置签名密码，编译脚本会自动回退到默认的 `debug` 证书进行签名，以防编译报错。
* **本地正式签名（可选）**：如果需要在本地进行与线上一致的正式签名打包，可在 `ownd-app/android/` 目录下创建 `key.properties`（该文件已加入 Git 忽略列表），并在其中配置证书密码（`storePassword`、`keyAlias`、`keyPassword`）。

---

## 📱 线上服务

| 服务 | 地址 |
|------|------|
| API | `https://api.ownd.cc` |
| MinIO 控制台 | `https://console.ownd.cc` |
| 个人博客 | `https://blog.ownd.cc` |

---

## 📄 License

MIT © [EF1874](https://github.com/EF1874)
