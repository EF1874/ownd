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

---

## 阶段 2：V2.0 & V3.0 (已完成)

### [DONE] TSK-2.1: 分类管理 (Category CRUD)
- **成果**: 实现树状分类结构及其 CRUD，支持全局与自定义分类隔离。

### [DONE] TSK-3.2: 基础 Timeline 架构
- **成果**: 建立 `LoggerMiddleware` 请求监控体系，架构设计已对齐 Flutter。

---

## 阶段 3：V4.0 全生命周期与财务统计 (当前阶段)

### [TODO] TSK-4.1: Prisma Schema 升级 (Prisma 7 标准)
- **方案**: 增加 `CycleType` 枚举、`Platform` 模型、以及具备 `RecordType` (RENEWAL/MAINTENANCE/UPGRADE) 的 `ItemHistory` 模型。
- **配置**: 顺带修复 Prisma 7 的 datasource URL 警告，确保符合新一代配置标准。

### [TODO] TSK-4.2: 购买平台 (Platform) 模块
- **方案**: 实现平台的字典化管理，支持多用户隔离。

### [TODO] TSK-4.3/4.4: 物品生命周期与统一历史记录
- **方案**: 
    - 升级 `ItemsService` 以处理备用、报废、年限等逻辑。
    - 增加 `ItemHistoryController` 实现 **续费、维修、升级** 记录的统一 CRUD。

### [TODO] TSK-4.5: 统计引擎 (Statistics Engine)
- **方案**: 实现 `GET /items/statistics`。逻辑需在后端 Service 镜像实现 Flutter 的 `dailyCost` 算法。

---

## 验收标准 (Milestone 2)
- [ ] 数据库完成 Schema 扩展且无数据丢失。
- [ ] 物品详情返回全量生命周期字段及历史记录。
- [ ] 统计接口返回的总额与日均成本与前端计算一致。
- [ ] 支持针对每一期订阅历史的独立 CRUD。

## Verification Plan
- **自动化测试**: 运行 `npm run test`。
- **静态检查**: 运行 `npm run lint` 确保 0 报错（符合“零错误准则”）。
- **逻辑对齐**: 对比后端计算结果与 Flutter 对应算法的输出。
