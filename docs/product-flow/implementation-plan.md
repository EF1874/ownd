# 实施计划 (Implementation Plan) - Ownd Backend

# 实施计划 (Implementation Plan) - Ownd Backend

## 阶段 1：V1.0 核心基础 (本周目标 - 进行中)

### [DONE] TSK-1.1: NestJS 初始化与环境变量配置
- **操作描述**: 使用 Nest CLI 初始化项目并安装基础依赖。

### [DONE] TSK-1.2: Docker Compose 配置
- **操作描述**: 编写 `docker-compose.yaml` 并启动基础服务（PG, Redis, MinIO）。

### [DONE] TSK-1.3: Prisma Schema 定义与 Migration
- **操作描述**: 定义 `User`, `Item`, `Category` 模型并执行迁移。

### [DONE] TSK-1.4: Auth 模块实现 (JWT)
- **操作描述**: 实现登录、注册、密码哈希（bcrypt）及 JWT 签发。

### [DONE] TSK-1.5: 全局 API 规范化
- **操作描述**: 实现 `TransformInterceptor` 和 `HttpExceptionFilter` 统一响应格式。

### [DONE] TSK-1.6: JWT Guard 与路由保护
- **操作描述**: 实现 `JwtAuthGuard` 和 `JwtStrategy`，确保接口安全性。

### [DONE] TSK-1.7: 物品管理接口 (CRUD)
- **操作描述**: 实现受保护的物品增删改查及所有权校验（基于 `userId`）。

### [WIP] TSK-1.8: MinIO 图片上传功能
- **操作描述**: 开发 `MinioModule` 和图片上传接口。
- **关键细节**: 支持 `multipart/form-data`，自动处理桶初始化，并关联物品记录。

---

## 验收标准 (Milestone 1)
- [x] 后端服务成功启动且能连接数据库。
- [ ] Swagger 文档可访问 (待完成)。
- [x] JWT 登录与路由拦截机制生效。
- [x] 物品管理 CRUD 具备完善的归属权校验逻辑。
- [ ] 物品可以成功上传图片并在 MinIO 中持久化。

## Verification Plan
- **自动化测试**: 运行 `npm run test` 确保所有 Service 和 Controller 逻辑正确。
- **手动验证**: 使用 RestClient 模拟全链路业务流程。
