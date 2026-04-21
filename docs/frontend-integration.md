# Frontend Integration Guide (接入服务端指南)

本手册旨在指导前端 AI 工具将原有的 Local 模式迁移至 Server 模式。

## 1. 环境配置 (Env)
- **API Base URL**: `http://localhost:3000/api/v1`
- **Auth Header**: 必须包含 `Authorization: Bearer <JWT_TOKEN>`。

## 2. 身份验证流 (Authentication Flow)
- **持久化**: 建议将 `access_token` 存储在 `Flutter` 的 `SecureStorage` 或 Web 的 `LocalStorage` 中。
- **自动跳转**: 拦截 `401 Unauthorized` 响应，清除 Token 并引导用户跳转至登录页。

## 3. 物品与图片处理 (Items & Images)
- **获取列表**: 调用 `GET /items`。注意：后端已实现物理隔离，你只能获取到当前登录用户的物品。
- **图片展示**: 
  - 当前图片路径存储在 `imagePath` 字段。
  - **重要**: 访问 MinIO 图片需要配合后端的静态服务代理（待 TSK-1.9 进一步优化）或直接通过 MinIO URL。
- **上传图片**:
  - 使用 `multipart/form-data`。
  - 字段名必须为 `file`。

## 4. 异常处理映射
后端返回的错误格式如下，请在前端层进行统一解析并展示 `message`：
```json
{
  "statusCode": 400,
  "message": ["price must be a number"],
  "timestamp": "..."
}
```

## 5. 开发建议 (Next Steps for Frontend AI)
1. 实现 `AuthInterceptor` 自动注入 Token。
2. 将 `ItemsProvider` (或相应状态管理) 的数据来源从 `LocalDB` 切换为 `ApiService`。
3. 实现图片上传预览与上传逻辑。
