# Product Requirements Document

> 中文建议：默认用中文撰写，除非项目明确要求英文。

## Summary

- Product Name: Ownd Backend
- Problem: 为 Ownd Flutter 应用提供高性能、可扩展的后端支持，实现数据的云端同步、资产的全生命周期管理及深度数据分析。
- Primary Users: 需要跨设备同步物品数据的 Ownd 用户；需要深度分析资产价值、沉没成本和保修进度的重度物品持有者。
- Value Proposition: 提供稳定、安全的云端数据存储与计算能力，提升用户资产管理效率。

## Goals

- **身份认证 (Auth)**: 基于 JWT 的无状态登录，支持基本的用户注册与权限管理。
- **全生命周期管理 (Lifecycle)**: 追踪物品从入库 (Purchase) 到备用 (Backup) 再到报废 (Scrapped) 的完整过程。
- **订阅与维护追踪 (Cost Records)**: 针对虚拟物品（如软件服务）和实体物品（如硬件维修），记录每一期的缴费、维修或升级记录 (History)。
- **统一支出分析**: 汇总购买、续费、维修及升级的所有支出，提供物品全生命周期的总拥有成本 (TCO) 分析。
- **平台化体系 (Platforms)**: 建立购买平台字典表，支持针对购买渠道的资产分布分析。
- **统计引擎 (Stats Engine)**: 后端实现与前端一致的财务计算逻辑（日均成本、总资产现值、月度订阅支出总额）。
- **统一响应规范**: 所有的 API 必须符合 `{"code": number, "data": any, "msg": string}` 格式。

## Non-Goals

- 暂不支持社交分享功能。
- 暂不支持第三方支付集成。

## Core User Scenarios

1. **全链路资产追踪**：用户在购买 MacBook 后录入系统，随后在两年后将其标记为“备用”，系统自动记录时间点，并停止其核心折旧计算。
2. **订阅续费管理**：用户添加 Netflix 订阅，录入每一期的账单。后端计算其过去一年的总支出，并提醒下个周期的扣费时间。
3. **多设备同步**：用户在手机端修改物品分类，所有关联的统计数据（分类占比、月度花费）在全平台实时同步。

## MVP Scope

- 身份认证模块
- 物品全维度 CRUD（含生命周期字段）
- 订阅历史管理接口 (History CRUD)
- 分类与购买平台字典管理
- 综合统计接口 (Global Statistics)

## Future Scope

- 资产价值趋势分析图表
- 物品保修到期/账单到期邮件提醒
- 社区资产评价系统

## Acceptance Criteria

- 所有财务计算逻辑必须与 Flutter 端 `device.dart` 中的算法保持一致。
- 支持物品在不同状态（Active/Backup/Scrapped）下的过滤查询。
