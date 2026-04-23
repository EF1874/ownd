# 架构决策记录 (ADR)

## [AD-001] 技术栈选型
- **决策**: 使用 NestJS + Prisma + PostgreSQL。
- **理由**: 类型安全、生产级框架、强大的 ORM 支持。

## [AD-002] 认证机制
- **决策**: 采用 Passport-JWT 策略。
- **理由**: 无状态、易于扩展、标准化的 NestJS 实现方式。

## [AD-003] 统一响应格式
- **决策**: 使用全局拦截器封装返回结构 `{ data: T, statusCode: number }`。

## [AD-004] 异常处理扁平化
- **决策**: 自定义 `HttpExceptionFilter`，确保错误信息以统一的 JSON 格式返回给前端。

## [AD-005] 实时数据库回查
- **决策**: JWT Strategy 在验证载荷后，通过 `usersService` 查询数据库确认用户依然存在且活跃。

## [AD-006] 服务层强制归属权隔离
- **决策**: 在 `Prisma` 查询时，非公开接口强制要求传入 `userId` 过滤条件，防止越权漏洞。

## [AD-007] 文件上传安全约束策略
- **决策**: 在 `ItemsController` 层面使用 `ParseFilePipe`。
- **约束**: 强制限制文件大小（1MB）及 MIME 类型（image/*），在进入 Service 前拦截非法附件。

## [AD-008] 存储桶自动初始化
- **决策**: MinIO 在服务启动时自动检查并创建 `ownd-items` 存储桶。

## [AD-009] 统一物品历史与成本记录表 (Unified Cost Records)
- **决策**: 将物品的“订阅续费 (Renewal)”、“硬件维修 (Maintenance)”以及“组件升级 (Upgrade)”全部统一存储在 `ItemHistory` 表中。
- **理由**: 
    1. **简化统计**：计算物品累计总投入时，只需对该表进行一次 SUM 聚合。
    2. **对齐 UI**：Flutter 端的时间轴节点 (TimelineNode) 本质上就是这些记录的展示。
    3. **可维护性**：统一的 CRUD 接口即可管理所有类型的历史记录，降低系统复杂度。
