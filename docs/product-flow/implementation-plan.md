# 实施计划 (Implementation Plan) - Ownd Backend

## 阶段 1：V1.0 核心基础 (已完成)

### [DONE] TSK-1.1 - 1.5: 基础架构、数据库与认证
- **成果**: NestJS 基础、Docker 服务、Prisma Schema、JWT Auth、全局响应标准。

### [DONE] TSK-1.7: 物品管理接口 (CRUD)
- **成果**: 实现受保护的物品增删改查及基于 `userId` 的所有权安全校验。

### [DONE] TSK-1.8/3.1: MinIO 图片上传功能
- **成果**: 完成 `MinioService` 开发，支持 1MB 限制及图片 MIME 类型校验。
- **单元测试**: 100% 绿通 (17/17 cases)。

### [DONE] TSK-1.6: Swagger API 文档集成
- **成果**: 完成 `@nestjs/swagger` 配置，支持 JWT 认证描述及 DTO 自动扫描。
- **验证**: 编写并跑通了 `src/test/swagger.spec.ts` 自动化 E2E 测试。

---

## 阶段 2：V2.0 业务能力 (当前阶段)

### [TODO] TSK-2.1: 分类管理 (Category CRUD)
- **目标**: 实现物品的分类逻辑。

---

## 验收标准 (Milestone 1)
- [x] 后端服务成功启动且能连接数据库。
- [x] Swagger 文档可访问且通过自动化验证。
- [x] JWT 登录 with 路由拦截机制生效。
- [x] 物品管理 CRUD 具备完善的归属权校验逻辑。
- [x] 物品可以成功上传图片并在 MinIO 中持久化。

## Verification Plan
- **自动化测试**: 运行 `npm run test`。
- **Swagger 验证**: 运行 `node node_modules/jest/bin/jest.js src/test/swagger.spec.ts`。
- **静态检查**: 运行 `npm run lint` 确保 0 报错。
