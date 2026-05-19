# Frontend Integration Guide (接入服务端指南)

本手册旨在指导前端 AI 工具将原有的 Local 模式迁移至 Server 模式。

## 1. 环境配置 (Env)
- **Android 模拟器 API Base URL**: `http://10.0.2.2:3000/api/v1`
- **本机/桌面 API Base URL**: `http://localhost:3000/api/v1`
- **Auth Header**: 必须包含 `Authorization: Bearer <JWT_TOKEN>`。
- Flutter 可通过 `--dart-define=OWND_API_BASE_URL=<url>` 覆盖默认地址。

## 2. 身份验证流 (Authentication Flow)
- **持久化**: 当前 Flutter 端使用 `flutter_secure_storage` 保存 `access_token`。
- **自动跳转**: 拦截 `401 Unauthorized` 响应，清除 Token 并引导用户跳转至登录页。
- **登录响应**: 从 `data.access_token` 读取 JWT，从 `data.user` 读取当前用户。

## 3. 物品与图片处理 (Items & Images)
- **获取列表**: 调用 `GET /items`。注意：后端已实现物理隔离，你只能获取到当前登录用户的物品。
- **图片展示**: 
  - 当前图片路径存储在 `imagePath` 字段。
  - **重要**: 访问 MinIO 图片需要配合后端的静态服务代理（待 TSK-1.9 进一步优化）或直接通过 MinIO URL。
- **上传图片**:
  - 使用 `multipart/form-data`。
  - 字段名必须为 `file`。

## 4. 异常处理映射
后端目标错误协议如下，请在前端层统一解析并展示 `msg`：
```json
{
  "code": 400,
  "data": null,
  "msg": "price must be a number",
  "timestamp": "..."
}
```

> 兼容说明：历史版本可能返回 `message`，在 R1 完成前建议前端兼容读取 `msg ?? message`。

## 5. 当前 Flutter 接入状态
1. 已实现 `Dio` API Client、Bearer Token 注入、`msg/message` 错误解析。
2. 已实现登录/注册页面、Token 持久化、未登录路由拦截。
3. `DeviceRepository` 与 `CategoryRepository` 已切换为在线优先远程 DataSource。
4. 当前图片仍以本地预览为主；完整远程图片展示依赖后端 MinIO 公开 URL 或代理接口。
