# App Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Android app update checking from the profile version row, backed by release metadata and APK assets published by GitHub Actions.

**Architecture:** GitHub Actions builds release APKs, uploads immutable ABI-specific assets and production `android/latest.json` to MinIO-compatible storage, and cleans old objects with a 7-day / 5-version retention policy. Local debugging uses `.tmp_update_server/latest.json`. The NestJS API exposes a stable `app-updates/latest` endpoint that proxies the configured manifest address. Flutter checks that endpoint, selects the APK that matches the Android device ABI, downloads it, verifies sha256, and opens the Android system installer.

**Tech Stack:** Flutter, Riverpod, Dio, package_info_plus, open_file, crypto, NestJS, MinIO-compatible S3 storage, GitHub Actions.

---

### Task 1: Backend Update Metadata Endpoint

**Files:**
- Create: `ownd-api/src/app-updates/app-updates.module.ts`
- Create: `ownd-api/src/app-updates/app-updates.controller.ts`
- Create: `ownd-api/src/app-updates/app-updates.service.ts`
- Create: `ownd-api/src/app-updates/dto/app-update.dto.ts`
- Modify: `ownd-api/src/app.module.ts`
- Modify: `ownd-api/.env.production.example`

- [x] Add a public `GET /api/v1/app-updates/latest?platform=android` endpoint.
- [x] Read the platform manifest URL from env, fetch it, validate required fields, and return it through the existing response wrapper.
- [x] Add focused Jest tests for happy path, missing config, unsupported platform, and invalid manifest.

### Task 2: Flutter Update Flow

**Files:**
- Create: `ownd-app/lib/shared/services/app_update_service.dart`
- Modify: `ownd-app/lib/features/profile/profile_screen.dart`
- Modify: `ownd-app/pubspec.yaml`
- Modify: `ownd-app/android/app/src/main/AndroidManifest.xml`

- [x] Add update metadata models and an `AppUpdateService`.
- [x] Compare current `buildNumber` with `versionCode`.
- [x] Download APK to a temporary file with progress.
- [x] Verify sha256 before opening the APK with the Android installer.
- [x] Make the profile version row tappable and show update states.

### Task 3: Release Pipeline and Storage Retention

**Files:**
- Create: `ownd-app/scripts/select-release-objects-to-delete.mjs`
- Modify: `.github/workflows/release-app.yml`
- Modify: external gateway repo `C:\code\project\caddy-gateway\Caddyfile`
- Modify: `ownd-api/.env.production.example`

- [x] Build a universal APK for in-app update.
- [x] Generate `latest.json` with version, versionCode, ABI artifacts, universal fallback fields, release notes, and retention policy.
- [x] Upload APK and manifest to S3-compatible storage when storage secrets are present.
- [x] Delete objects older than 7 days and keep at most the latest 5 versions inside that window, while protecting the current latest version.

### Task 4: Verification

- [x] Run focused backend tests for app updates.
- [x] Run backend build.
- [x] Run Flutter analyze.
- [x] Inspect git diff for accidental unrelated changes.
