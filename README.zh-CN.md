<p align="center">
  <img src="ownd-app/assets/icon.png" width="120" alt="Ownd 标志" />
</p>

<h1 align="center">Ownd — 物记</h1>
<p align="center">
  <strong>个人数字资产管理平台</strong><br />
  追踪你拥有的物品、订阅和数字资产。
</p>

<p align="center">
  <a href="./README.md">English</a> · <strong>简体中文</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter" alt="Flutter 3.41" />
  <img src="https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs" alt="NestJS 11" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 16" />
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white" alt="Redis 7" />
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" /></a>
</p>

## 项目简介

Ownd 是一个可自行部署的个人资产管理系统，将移动端、后端 API、数据库、对象存储和自动化发布流程整合在同一个仓库中。它可以记录实体物品、订阅和数字资产，并持续追踪它们从购入到退役的完整生命周期。

## 功能亮点

- **物品全生命周期管理**：记录购买、使用、转手和退役历史。
- **资产统计看板**：分析总拥有成本（TCO）、日均持有支出等数据。
- **分类与平台标签**：通过自定义分类和平台管理资产来源。
- **安全认证**：使用 JWT 令牌与 Redis 黑名单管理会话。
- **云端同步**：使用 MinIO 对象存储上传和备份图片。
- **自动化交付**：通过 Docker Compose 和 GitHub Actions 完成部署与发布。

## 技术架构

| 层级 | 技术栈 |
| --- | --- |
| 移动端 | Flutter 3.41 · Dart · Riverpod · Isar |
| 后端 API | NestJS 11 · TypeScript · Prisma ORM |
| 数据库 | PostgreSQL 16 · Redis 7 |
| 对象存储 | MinIO（S3 兼容） |
| 反向代理 | Caddy 2（自动 HTTPS） |
| CI/CD | GitHub Actions |

## 仓库结构

```text
ownd/
├── .github/workflows/           # 自动部署与发布流程
├── ownd-api/                    # NestJS 后端 API
│   ├── src/                     # 认证、物品、分类等业务模块
│   ├── prisma/                  # 数据库模型与迁移
│   ├── deploy/                  # Caddy 配置
│   ├── docker-compose.yaml      # 本地依赖服务
│   └── docker-compose.prod.yaml # 生产环境编排
├── ownd-app/                    # Flutter 移动端应用
│   ├── lib/                     # Dart 业务代码
│   ├── android/                 # Android 配置
│   ├── ios/                     # iOS 配置
│   └── config/                  # 开发与生产环境配置
└── README.md
```

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/EF1874/ownd.git
cd ownd
```

### 2. 启动后端

请先安装 Node.js、pnpm 和 Docker。

```bash
cd ownd-api
pnpm install
cp .env.example .env.development
docker compose up -d
npx prisma migrate dev
npx prisma generate
pnpm run start:dev
```

### 3. 运行移动端应用

请先安装 Flutter 和对应平台的开发工具。

局域网联调时，后端会生成包含当前电脑局域网 IP 的 `ownd-app/config/local.json`：

```bash
cd ownd-app
pnpm android:dev:install
```

也可以手动指定 API 地址：

```bash
cd ownd-app
flutter pub get
flutter run --dart-define=OWND_API_BASE_URL="http://localhost:3000/api/v1"
```

连接线上 API：

```bash
flutter run --dart-define=OWND_API_BASE_URL="https://api.ownd.cc/api/v1"
```

## 自动化部署与发布

| 工作流 | 触发条件 | 功能 |
| --- | --- | --- |
| Deploy Backend | 将 `ownd-api/**` 推送到 `master` | 构建并部署后端服务 |
| Release App | 修改 `ownd-app/pubspec.yaml` 中的版本号 | 构建 Android APK 并创建 GitHub Release |
| Update App Release Notes | 手动触发 | 更新已发布版本的说明文本 |

GitHub Actions 中的正式 Release 使用加密 Secrets 完成 Android 生产签名。本地未配置生产签名时使用调试签名，适合开发和测试。请勿将签名文件、密码或生产环境变量提交到仓库。

## 在线服务

- API：`https://api.ownd.cc`

## 许可证

本项目采用 [MIT License](./LICENSE)，版权所有 © 2026 Cong Li。