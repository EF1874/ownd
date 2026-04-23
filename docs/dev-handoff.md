# 开发文档：物品生命周期与财务历史系统

## 1. 核心架构设计

为了支持“资产价值追踪”和“订阅成本管理”，系统引入了物品生命周期（Lifecycle）和历史记录（ItemHistory）机制。

### 1.1 物品模型增强 (Item Model)
- **`isVirtual`**: 布尔值。定义物品是否为虚拟资产/订阅（如 Netflix, iCloud）。这是财务计算的 **Source of Truth**。
- **生命周期日期**:
    - `purchaseDate`: 购买/起租日期。
    - `warrantyEndDate`: 保修截止日期。
    - `backupDate`: 闲置/备用开始日期。
    - `scrappedDate`: 报废/停用日期。
- **订阅控制**:
    - `currentCycleType` / `currentCycle`: 当前订阅周期（如 1 MONTH）。
    - `nextBillingDate`: 系统自动计算的下一次扣费日期。

### 1.2 自动初始化逻辑
在 `ItemsService.create` 中，如果物品标记为 `isVirtual`，系统会执行以下原子操作：
1.  **日期计算**：使用 `dayjs` 根据购买日期和周期算出该周期的结束日期。
2.  **自动续费记录**：在 `ItemHistory` 表中插入第一条类型为 `RENEWAL` 的记录。
3.  **计算下期账单日**：设置物品的 `nextBillingDate` 为结束日期的后一天。

## 2. 开发者接手指南 (Handoff)

### 当前进度 (2026-04-23)
- [x] **基建完成**：Prisma Schema 已同步，所有 Entity 均已实现接口。
- [x] **创建逻辑**：物品创建时的自动历史生成和周期计算已完成并验证。
- [x] **Lint 状态**：`src` 目录下 0 报错。

### 待办任务 (Backlog)
1.  **统计引擎 (Statistics Engine)**：
    - **位置建议**：创建 `statistics` 模块。
    - **目标**：计算 TCO (Total Cost of Ownership) = 某个物品所有历史记录金额总和。
    - **目标**：计算日均成本 = 当前周期金额 / 周期天数。
2.  **历史记录管理接口**：
    - 需要实现 `POST /items/:id/histories` 供用户手动补录维修、升级等费用。
3.  **过期检查机制**：
    - 需要一个 Trigger 或 Cron 来处理已到达 `nextBillingDate` 的物品。

### 测试验证
- 验证脚本位置：`scratch/verify-lifecycle.ts`
- 运行命令：`powershell -ExecutionPolicy Bypass -Command "npx ts-node scratch/verify-lifecycle.ts"`

## 3. 重要注意事项
- **日期处理**：必须统一使用 `dayjs` 库，确保计算逻辑一致。
- **字段命名**：所有模型强制使用 `createdAt` 和 `updatedAt`（带 `d`）。
- **权限安全**：所有查询必须带上 `userId` 过滤，严禁越权访问。
