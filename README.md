# Ownd - 个人数字资产管理平台

Ownd 是一个全栈的个人数字资产与订阅管理平台，采用前后端分离的架构：
- **后端**：使用 NestJS + PostgreSQL + Prisma + Redis + MinIO 搭建，支持分布式部署及高性能缓存。
- **前端**：使用 Flutter 跨平台框架构建，支持 Android、iOS 以及桌面端，提供流畅的移动端交互体验。

---

## 📂 项目目录结构

当前项目采用 **多仓库联合（Git Submodules）** 的元仓库架构进行管理：

```text
ownd/ (总仓库)
├── .github/                # GitHub Actions 自动化流水线配置
│   └── workflows/
│       ├── deploy-backend.yml # 后端自动部署流水线
│       └── release-app.yml    # 移动端 App 自动编译打包流水线
├── .vscode/                # VS Code 推荐开发环境配置
├── docs/                   # 项目深度设计与运维文档
│   ├── deployment-vps.md   # 服务器 VPS 部署指南
│   ├── api-reference.md    # 后端 API 接口设计参考
│   └── frontend-integration.md # 前后端接口联调说明
├── ownd-api/               # [Git Submodule] 后端 NestJS 项目目录
└── ownd-app/               # [Git Submodule] 前端 Flutter 移动端项目目录
```

---

## 🚀 开发者快速上手

### 1. 克隆项目
由于项目包含 Git 子模块，克隆时必须携带 `--recursive` 参数以完整拉取子项目源码：
```bash
git clone --recursive https://github.com/your-username/ownd.git
```
如果已经克隆了总仓库，但子项目文件夹为空，请运行以下命令进行初始化：
```bash
git submodule update --init --recursive
```

### 2. 本地开发环境启动

#### 后端开发环境 (ownd-api)
1. 安装并进入依赖：
   ```bash
   cd ownd-api
   pnpm install
   ```
2. 确保本地拥有 Docker 并运行基础设施（数据库、Redis、MinIO 等）：
   ```bash
   docker compose up -d
   ```
3. 复制本地开发环境变量配置：
   ```bash
   cp .env.example .env.development
   ```
4. 运行 Prisma 迁移以初始化数据库表结构：
   ```bash
   npx prisma migrate dev
   ```
5. 启动后端服务：
   ```bash
   pnpm run start:dev
   ```

#### 移动端开发环境 (ownd-app)
1. 确保已安装 Flutter SDK（版本 3.41+），并在 `ownd-app` 目录下运行：
   ```bash
   cd ownd-app
   flutter pub get
   ```
2. 选择开发环境配置并运行：
   ```bash
   flutter run --dart-define=OWND_API_BASE_URL="http://localhost:3000/api/v1"
   ```

---

## 🌐 自动化部署 (CI/CD) 说明

项目的所有自动化构建与部署已完全托管在 GitHub Actions 中：
- **后端自动更新**：任何提交到 `master` 分支且涉及 `ownd-api/` 目录的修改，将自动触发云服务器（Tencent Cloud）的拉取和 `docker-compose.prod.yaml` 重建，实现零停机热升级。
- **App 自动发布**：在总仓库中推送版本号 Tag（如 `v1.1.0`）或修改了 `ownd-app/pubspec.yaml` 时，将自动使用 JDK 17 构建 Android 生产环境 APK，并在 GitHub 上创建一个新的 Release 供用户下载。

详细的运维配置及网络隔离（Caddy 端口隐蔽）请参见 [docs/deployment-vps.md](file:///c:/code/project/ownd/docs/deployment-vps.md)。
