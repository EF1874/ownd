# Architecture

> 中文建议：重点说明系统边界、模块职责、数据流和风险，不必一开始写得过细。

## System Summary

# 架构设计 (Architecture) - Ownd Backend

## 设计思想
采用 **模块化单体 (Modular Monolith)** 结合 **整洁架构 (Clean Architecture)**。

## 逻辑分层
1. **Interfaces Layer (API)**:
   - 控制器 (Controllers)
   - 数据传输对象 (DTOs) 配合 `class-validator`
2. **Application Layer (Use Cases)**:
   - 业务逻辑编排 (Services)
   - 事件发射 (Event Emitters)
3. **Domain Layer (Core Entities)**:
   - Prisma 模型定义的实体
   - 核心业务规则 (如成本计算公式)
4. **Infrastructure Layer**:
   - Prisma Client (PostgreSQL)
   - Redis (Cache/Rate Limit)
   - MinIO (Local Object Storage)

## Major Components

## 核心模块
- `AuthModule`: 登录、令牌签发。
- `UserModule`: 用户资料。
- `ItemsModule`: 物品核心 CRUD、生命周期字段维护、图片上传入口。
- `CategoriesModule`: 分类树 CRUD 与用户隔离。
- `StatisticsModule`: 统计能力承载模块（当前仅模块壳，待实现 Service/Controller）。
- `PlatformModule`: 购买平台字典模块（待落地）。

## 边界与职责约束
- Controller 仅负责协议层（DTO 校验、鉴权注解、输入输出）。
- Service 承载业务规则（生命周期计算、历史记录策略、权限边界）。
- Prisma 层只做数据访问，不承载业务分支判断。
- 全局拦截器/过滤器负责统一响应与错误出参契约。

## Data Flow

1. 客户端携带 JWT 访问 `/api/v1/*`。
2. `JwtAuthGuard + JwtStrategy` 完成身份校验，注入 `request.user`。
3. Controller 通过 DTO 与 Pipe 完成参数校验和转换。
4. Service 执行业务逻辑并通过 Prisma 持久化。
5. 全局 Interceptor/Filter 将结果统一为标准 JSON 协议返回。

## External Dependencies

- PostgreSQL
- MinIO
- Prisma + `@prisma/adapter-pg`
- Swagger (`@nestjs/swagger`)

## Risks

- **RISK-01 (High)**: `items/:id/image` 路径中 `findOne` 参数顺序错误，可能导致权限校验错位。
- **RISK-02 (High)**: 响应协议字段与 PRD 契约不一致（`message` vs `msg`）。
- **RISK-03 (Medium)**: Lint 质量门当前失败，影响持续交付基线。
- **RISK-04 (Medium)**: JWT 使用 email 查询用户，主标识稳定性不足。
- **RISK-05 (Medium)**: MinIO 缺少 fail-fast 保护，错误可能延后暴露。
- **RISK-06 (Medium)**: 迁移中存在“新增非空字段无默认值”场景，需要三步迁移策略。

## Open Questions

- 统计模块是否在 V4 直接引入缓存层（Redis）还是先以 DB 聚合版本上线？
- ItemHistory 是否需要在首版支持分页与筛选（按类型/时间）？
- 过期检查机制采用 Cron 还是事件驱动，是否纳入 V4.0 范围？
