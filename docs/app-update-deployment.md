# App Update Deployment

## Manifest Files

- Production uses `latest.json`.
- Local debugging also uses `latest.json`.
- The Flutter app always calls the API endpoint. The environment decides which address the API or local proxy reads.
- `latest.json` contains `artifacts`, so Android can download the package that matches the device ABI. The top-level `apkUrl`, `apkSizeBytes`, and `sha256` stay as the universal package for old app versions.

## Local Debugging

Local testing uses the temporary proxy in `.tmp_update_server`:

- API endpoint: `http://127.0.0.1:3100/api/v1/app-updates/latest`
- Local manifest file: `.tmp_update_server/latest.json`
- Local manifest URL: `http://127.0.0.1:3100/latest.json`
- APK files: `.tmp_update_server/android/releases/...`

This proxy is only for local phone testing. It is not deployed to the server.

## Production Deployment

Production should not run the temporary `3100` proxy. The production flow is:

1. GitHub Actions builds the Android APK.
2. GitHub Actions uploads versioned APK files for each ABI plus `android/latest.json` to the MinIO bucket `ownd-releases`.
3. The production API reads `APP_UPDATE_ANDROID_MANIFEST_URL=https://download.ownd.cc/android/latest.json`.
4. The independent gateway project `C:\code\project\caddy-gateway` routes `download.ownd.cc/android/*` to the MinIO release bucket.

With this setup, the API service only needs a manifest URL. If storage moves to a new server later, update the Caddy gateway target or the manifest URL; the app update API and Flutter client do not need to change.

## Caddy Ownership

The Ownd API project no longer owns a Caddyfile. Keep all Caddy routes in the gateway project because this server hosts multiple projects behind one Caddy instance.

For a larger company or a single-project server, each project often owns its own ingress configuration. For the current single-server, multi-project setup, the shared gateway repo is the cleaner choice.

Current gateway route:

```caddy
download.ownd.cc {
	handle_path /android/* {
		rewrite * /ownd-releases/android{path}
		reverse_proxy ownd-minio-prod:9000
	}
}
```

After changing the gateway on the server, reload Caddy from `C:\code\project\caddy-gateway` with:

```powershell
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

The current `caddy-gateway` GitHub Actions workflow already copies the gateway files to the server and runs `docker compose up -d` plus `caddy reload`. Pushing gateway changes to `main` is enough when the workflow secrets and server path are configured correctly.
