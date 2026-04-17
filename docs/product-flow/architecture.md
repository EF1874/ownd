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
- `ItemModule`: 物品核心 CRUD 与统计。
- `TimelineModule`: 基于事件的异步变更记录。

- TBD

## Data Flow

{{ ... }}

## External Dependencies

- TBD

## Risks

- TBD

## Open Questions

- TBD
