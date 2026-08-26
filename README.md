<p align="center">
  <img src="ownd-app/assets/icon.png" width="120" alt="Ownd logo" />
</p>

<h1 align="center">Ownd — 物记</h1>
<p align="center">
  <strong>Personal Digital Asset Manager</strong><br />
  Track the items, subscriptions, and digital assets you own.
</p>

<p align="center">
  <strong>English</strong> · <a href="./README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter" alt="Flutter 3.41" />
  <img src="https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs" alt="NestJS 11" />
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL 16" />
  <img src="https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white" alt="Redis 7" />
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" /></a>
</p>

## Overview

Ownd is a self-hostable personal asset management system that brings together a mobile application, backend API, database, object storage, and automated delivery workflows in one repository. It manages physical items, subscriptions, and digital assets while preserving their history from purchase through retirement.

## Highlights

- **Full asset lifecycle**: Record purchases, usage, transfers, and retirement history.
- **Analytics dashboard**: Analyze total cost of ownership (TCO), average daily holding cost, and related metrics.
- **Categories and platforms**: Organize assets with custom categories and source platforms.
- **Secure authentication**: Manage sessions with JWT tokens and a Redis-backed blacklist.
- **Cloud synchronization**: Upload and back up images through MinIO object storage.
- **Automated delivery**: Deploy and release with Docker Compose and GitHub Actions.

## Architecture

| Layer | Technologies |
| --- | --- |
| Mobile app | Flutter 3.41 · Dart · Riverpod · Isar |
| Backend API | NestJS 11 · TypeScript · Prisma ORM |
| Data stores | PostgreSQL 16 · Redis 7 |
| Object storage | MinIO (S3-compatible) |
| Reverse proxy | Caddy 2 (automatic HTTPS) |
| CI/CD | GitHub Actions |

## Repository Structure

```text
ownd/
├── .github/workflows/           # Automated deployment and release workflows
├── ownd-api/                    # NestJS backend API
│   ├── src/                     # Auth, items, categories, and other modules
│   ├── prisma/                  # Database schema and migrations
│   ├── deploy/                  # Caddy configuration
│   ├── docker-compose.yaml      # Local supporting services
│   └── docker-compose.prod.yaml # Production orchestration
├── ownd-app/                    # Flutter mobile application
│   ├── lib/                     # Dart application code
│   ├── android/                 # Android configuration
│   ├── ios/                     # iOS configuration
│   └── config/                  # Development and production configuration
└── README.md
```

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/EF1874/ownd.git
cd ownd
```

### 2. Start the backend

Install Node.js, pnpm, and Docker first.

```bash
cd ownd-api
pnpm install
cp .env.example .env.development
docker compose up -d
npx prisma migrate dev
npx prisma generate
pnpm run start:dev
```

### 3. Run the mobile application

Install Flutter and the development tools for your target platform first.

For local network development, the backend generates `ownd-app/config/local.json` with the current computer's LAN address:

```bash
cd ownd-app
pnpm android:dev:install
```

You can also provide the API address manually:

```bash
cd ownd-app
flutter pub get
flutter run --dart-define=OWND_API_BASE_URL="http://localhost:3000/api/v1"
```

To connect to the hosted API:

```bash
flutter run --dart-define=OWND_API_BASE_URL="https://api.ownd.cc/api/v1"
```

## Deployment and Releases

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| Deploy Backend | Push changes under `ownd-api/**` to `master` | Build and deploy the backend service |
| Release App | Change the version in `ownd-app/pubspec.yaml` | Build an Android APK and create a GitHub Release |
| Update App Release Notes | Manual trigger | Update the text for an existing release |

Production releases built by GitHub Actions use encrypted secrets for Android signing. Local builds without production signing use debug signing for development and testing. Never commit signing files, passwords, or production environment variables.

## Hosted Service

- API: `https://api.ownd.cc`

## License

This project is licensed under the [MIT License](./LICENSE). Copyright © 2026 Cong Li.