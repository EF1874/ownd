# API Reference (Ownd Backend)

本文档记录了当前系统中已实现的接口契约，供前端或其他工具参考。所有接口的基础路径为 `/api/v1`。

## 响应协议说明（重要）

- **目标协议（PRD 基线）**: `{"code": number, "data": any, "msg": string}`
- **当前状态**: 成功响应由全局拦截器包装为 `code/data/msg`；错误响应以 `msg` 为标准字段，客户端可兼容历史 `message`。

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
    "code": 200,
    "data": {
      "access_token": "jwt_token_string",
      "user": {
        "id": "uuid",
        "email": "user@example.com",
        "name": "User Name"
      }
    },
    "msg": "success"
  }
  ```

### 当前用户资料
- **Method**: `GET`
- **Path**: `/auth/profile`
- **Header**: `Authorization: Bearer <token>`

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

### 更新物品
- **Method**: `PATCH`
- **Path**: `/items/:id`
- **Content-Type**: `application/json` 或 `multipart/form-data`

### 删除物品
- **Method**: `DELETE`
- **Path**: `/items/:id`

### 图片上传
- **Method**: `POST`
- **Path**: `/items/:id/image`
- **Content-Type**: `multipart/form-data`
- **Body**: `file` (Binary, < 1MB, image/jpeg|png)

### 历史记录管理 (History)
- **获取历史**: `GET /items/:id/histories`
- **添加记录**: `POST /items/:id/histories` (支持 RENEWAL, MAINTENANCE, UPGRADE, OTHER)
- **删除记录**: `DELETE /items/:id/histories/:historyId`

---

## 3. 平台管理 (Platform)
- **获取平台**: `GET /platform` (系统预设 + 个人自定义)
- **创建平台**: `POST /platform`
- **修改平台**: `PATCH /platform/:id`
- **删除平台**: `DELETE /platform/:id`

---

## 4. 分类管理 (Categories)
- **获取分类树**: `GET /categories` (返回树状结构)
- **创建分类**: `POST /categories`
- **修改分类**: `PATCH /categories/:id`
- **删除分类**: `DELETE /categories/:id` (级联删除)

---

## 5. 统计引擎 (Statistics)
- **资产概览**: `GET /statistics/summary` (返回总资产 TCO)
- **单项统计**: `GET /statistics/item/:id` (返回该物品的日均成本等)

---

## 全局规范
- **成功响应**: `200/201`
- **成功示例（目标）**:
  ```json
  {
    "code": 200,
    "data": {
      "id": "xxx"
    },
    "msg": "success"
  }
  ```
- **错误响应**:
  ```json
  {
    "code": 401,
    "msg": "Unauthorized",
    "timestamp": "2026-04-20T..."
  }
  ```
