# API Reference (Ownd Backend)

本文档记录了当前系统中已实现的接口契约，供前端或其他工具参考。所有接口的基础路径为 `/api/v1`。

## 1. 认证模块 (Auth)

### 注册 (Signup)
- **Method**: `POST`
- **Path**: `/auth/signup`
- **Payload**:
  ```json
  {
    "email": "user@example.com",
    "password": "strongpassword",
    "name": "User Name"
  }
  ```
- **Response**: `201 Created`

### 登录 (Login)
- **Method**: `POST`
- **Path**: `/auth/login`
- **Payload**:
  ```json
  {
    "email": "user@example.com",
    "password": "password"
  }
  ```
- **Response**:
  ```json
  {
    "access_token": "jwt_token_string"
  }
  ```

---

## 2. 物品管理 (Items)
> 所有接口均需 Header: `Authorization: Bearer <token>`

### 创建物品
- **Method**: `POST`
- **Path**: `/items`
- **Payload**:
  ```json
  {
    "name": "iPad Pro",
    "price": 7999,
    "notes": "2024 Model",
    "tags": ["electronic", "work"]
  }
  ```

### 获取所有物品 (仅限当前用户)
- **Method**: `GET`
- **Path**: `/items`

### 获取单个物品
- **Method**: `GET`
- **Path**: `/items/:id`

### 图片上传
- **Method**: `POST`
- **Path**: `/items/:id/image`
- **Content-Type**: `multipart/form-data`
- **Body**: `file` (Binary, < 1MB, image/jpeg|png)

---

## 全局规范
- **成功响应**: `200/201`
- **错误响应**:
  ```json
  {
    "statusCode": 401,
    "message": "Unauthorized",
    "timestamp": "2026-04-20T..."
  }
  ```
