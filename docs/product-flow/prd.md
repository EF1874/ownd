# Product Requirements Document

> 中文建议：默认用中文撰写，除非项目明确要求英文。

## Summary

- Product Name: Ownd Backend
- Problem: 为 Ownd Flutter 应用提供高性能、可扩展的后端支持，实现数据的云端同步、资产的全生命周期管理及深度数据分析。
- Primary Users: 需要跨设备同步物品数据的 Ownd 用户；需要深度分析资产价值、沉没成本和保修进度的重度物品持有者。
- Value Proposition: 提供稳定、安全的云端数据存储与计算能力，提升用户资产管理效率。

## Goals

- 身份认证 (Auth): 基于 JWT 的无状态登录，支持基本的用户注册与权限管理。
- 物品管理 (Items): 支持物品的 CRUD，实现日均成本、次均成本计算逻辑后端镜像化，记录订阅历史。
- 分类管理 (Categories): 实现全局与自定义分类的同步。
- 统一响应规范: 所有的 API 必须符合 `{"code": number, "data": any, "msg": string}` 格式。

## Non-Goals

- 暂不支持社交分享功能。
- 暂不支持第三方支付集成。

## Core User Scenarios

1. 用户在手机端添加物品，后端自动同步至云端，并在平板端实时更新。
2. 用户查看物品详情，后端计算并返回当前的日均使用成本。

## MVP Scope

- 身份认证模块
- 物品 CRUD 接口
- 分类管理接口
- 基础数据统计接口

## Future Scope

- 资产价值趋势分析
- 物品保修到期提醒推送
- 社区资产评价系统

## Acceptance Criteria

- TBD

## Open Questions

- TBD
