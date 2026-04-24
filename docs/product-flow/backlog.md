# Backlog (Ownd Backend)

## 当前里程碑

- Milestone: `V4.0 全生命周期与财务统计`
- 目标：在进入大规模功能开发前，先完成质量收敛与技术风险清零。

## 优先级任务清单

| ID | 类型 | 任务 | 优先级 | 状态 | 验收标准 |
|---|---|---|---|---|---|
| R1 | Contract | 统一 API 响应协议到 `{"code","data","msg"}` | P0 | TODO | 成功/失败响应均返回 `msg`；`api-reference.md` 与实现一致 |
| R2 | Bugfix | 修复 `items/:id/image` 中 `findOne` 参数顺序错误 | P0 | TODO | 上传图片接口不再误判权限，新增/更新测试通过 |
| R3 | Quality | 修复 lint 质量门（含 e2e tsconfig 包含问题） | P0 | TODO | `npm run lint` 0 error |
| R4 | Security | JWT validate 改为优先按 `sub(id)` 查询用户 | P1 | TODO | 邮箱变更不影响 token 验证一致性，鉴权测试通过 |
| R5 | Reliability | MinIO 配置改为 fail-fast + 启动健康检查 | P1 | TODO | 缺失关键配置时服务明确失败并给出可读错误 |
| R6 | Validation | 订阅周期字段校验增强（`currentCycle >= 1`） | P1 | TODO | 非法周期输入被 ValidationPipe 拦截 |
| R7 | Migration | TSK-4.1 迁移安全补强（非空字段与历史数据回填策略） | P1 | TODO | 迁移前后数据完整，`prisma migrate` 与校验脚本通过 |
| T4.2 | Feature | Platform 模块（controller/service/dto + userId 隔离） | P2 | TODO | 完成平台 CRUD 与权限隔离测试 |
| T4.3 | Feature | ItemHistory CRUD（从 `POST /items/:id/histories` 起步） | P2 | TODO | 续费/维修/升级记录可独立维护 |
| T4.5 | Feature | Statistics 模块落地（对齐 Flutter 算法） | P2 | TODO | `/items/statistics` 与前端算法对齐验证通过 |

## 执行流程约束（强制）

1. 每个任务必须先完成“讲解”并得到确认。
2. 再进入“引导实现”（保留关键思考位）。
3. 完成后进行“理解验证”（至少 1-2 个 why 问题）。
4. 最后由 AI 执行测试与验收回写文档。

## 文档联动规则

- 每完成一个任务，必须同步更新：
  - `docs/product-flow/current-status.md`
  - `docs/product-flow/implementation-plan.md`
  - `docs/product-flow/acceptance.md`
  - `docs/product-flow/decisions.md`（若涉及长期决策）
