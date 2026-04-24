# 技术选型 (Tech Stack) - Ownd Backend

## 服务端
- **框架**: NestJS (v11)
- **语言**: TypeScript
- **运行时**: Node.js (LTS, 推荐 20+)

## 数据层
- **ORM**: Prisma (v7 + `@prisma/adapter-pg`)
- **主数据库**: PostgreSQL
- **缓存**: Redis（规划中，用于统计缓存与限流）

## 基础设施
- **对象存储**: MinIO (本地私有化部署)
- **消息/事件**: 暂无（后续可按需求引入 `@nestjs/event-emitter`）
- **文档**: Swagger (@nestjs/swagger)

## 开发与部署
- **环境隔离**: Docker Compose (本地一键启动基础设施)
- **参数校验**: `class-validator`, `class-transformer`
- **CI/CD**: GitHub Actions (计划中，尚未落地 workflow)

## 发现的 Skills
- [x] NestJS Expert Skill
- [x] Prisma Master Skill
- [x] Docker Orchestrator Skill

## Selected Technologies

- Frontend Web: 暂无（当前重点为后端服务）
- Mobile: Flutter（消费方，需与其算法保持一致）
- Database: PostgreSQL + Prisma 7
- Cache / Queue / Storage: Redis(规划) / Queue(未选型) / MinIO(已落地)
- Proxy / Web Server: NestJS 内建 HTTP（反向代理待部署阶段确定）
- Containers / Runtime: Docker Compose + Node.js
- Deployment Platform: 待定（当前为本地开发环境）

## Skill Discovery

- Search Queries:
  - "nestjs backend best practices"
  - "prisma migration safety strategy"
  - "backend architecture review"
- Candidate Skills:
  - `software-architecture`
  - `product-manager`
  - `verification-before-completion`
- Approved Skills To Install:
  - 已启用：`software-architecture`, `product-manager`
  - 待实施前启用：`verification-before-completion`

## Installation Status

- Installed To Agent (`~/.agents/skills`): `software-architecture`, `product-manager`, `product-flow-orchestrator`
- Mirrored To Project (`skills/`): 暂无
- Missing Skills / To Create: 无强制缺口

## Testing And Quality

- Unit / Integration: Jest（已启用，持续补齐 V4 新模块测试）
- E2E: Swagger 文档相关 E2E 已有基础，业务 E2E 待补齐
- Lint / Format / Type Check:
  - `npm run build`：通过
  - `npx prisma validate`：通过
  - `npm run lint`：当前失败（`test/app.e2e-spec.ts` 项目包含问题，列入 P0）

## Notes

- 先确定技术选型，再查找和安装对应 skill。
- agent 环境是主安装位置，项目里的 `skills/` 适合镜像、定制和版本管理。
- 优先遵循项目现有约定，其次才是通用最佳实践。
- 在 V4 功能扩展前，必须先通过质量收敛任务 R1-R6。
