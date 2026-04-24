# 开发文档：物品生命周期与财务历史系统

## 1. 核心架构设计

为了支持“资产价值追踪”和“订阅成本管理”，系统引入了物品生命周期（Lifecycle）和历史记录（ItemHistory）机制。

### 1.1 物品模型增强 (Item Model)
- **`isVirtual`**: 布尔值。定义物品是否为虚拟资产/订阅（如 Netflix, iCloud）。这是财务计算的 Source of Truth。
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
1. 日期计算：使用 `dayjs` 根据购买日期和周期算出该周期的结束日期。
2. 自动续费记录：在 `ItemHistory` 表中插入第一条类型为 `RENEWAL` 的记录。
3. 计算下期账单日：设置物品的 `nextBillingDate` 为结束日期后一天。

## 2. 开发者接手指南 (Handoff)

### 当前进度
- [x] 基建完成：Prisma Schema 已同步，Entity 已覆盖生命周期核心字段。
- [x] 创建逻辑：虚拟物品创建时自动历史生成和周期计算已实现。
- [x] 质量门：`lint/build` 基线已恢复可用。

### 待办任务 (Backlog)
1. **统计引擎 (Statistics Engine)**：
   - 位置建议：`statistics` 模块。
   - 目标：计算 TCO（某物品历史记录金额总和）和日均成本。
2. **历史记录管理接口**：
   - 实现 `POST /items/:id/histories`，支持手工补录维修、升级等费用。
3. **过期检查机制**：
   - 设计 Trigger 或 Cron 处理 `nextBillingDate` 到期逻辑。

### 测试验证（统一自动化）
- 单元/集成：`npm run test`
- 静态检查：`npm run lint`
- 编译检查：`npm run build`

## 3. 重要注意事项
- 日期处理：统一使用 `dayjs`，保证计算逻辑一致。
- 字段命名：模型统一使用 `createdAt` 与 `updatedAt`。
- 权限安全：所有业务查询必须带 `userId` 过滤，禁止越权访问。
