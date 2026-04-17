# 技术选型 (Tech Stack) - Ownd Backend

## 服务端
- **框架**: NestJS (v10+)
- **语言**: TypeScript
- **运行时**: Node.js (LTS)

## 数据层
- **ORM**: Prisma
- **主数据库**: PostgreSQL
- **缓存**: Redis (用于缓存统计数据和接口限流)

## 基础设施
- **对象存储**: MinIO (本地私有化部署)
- **消息/事件**: `@nestjs/event-emitter` (进程内异步) -> 未来可扩展为 RabbitMQ/Kafka
- **文档**: Swagger (@nestjs/swagger)

## 开发与部署
- **环境隔离**: Docker Compose (本地一键启动基础设施)
- **参数校验**: `class-validator`, `class-transformer`
- **CI/CD**: GitHub Actions (计划中)

## 发现的 Skills
- [x] NestJS Expert Skill
- [x] Prisma Master Skill
- [x] Docker Orchestrator Skill

## Selected Technologies

- Frontend Web: TBD
- Mobile: TBD
- Database: TBD
- Cache / Queue / Storage: TBD
- Proxy / Web Server: TBD
- Containers / Runtime: TBD
- Deployment Platform: TBD

## Skill Discovery

- Search Queries: TBD
- Candidate Skills: TBD
- Approved Skills To Install: TBD

## Installation Status

- Installed To Agent (`~/.agents/skills`): TBD
- Mirrored To Project (`skills/`): TBD
- Missing Skills / To Create: TBD

## Testing And Quality

- Unit / Integration: TBD
- E2E: TBD
- Lint / Format / Type Check: TBD

## Notes

- 先确定技术选型，再查找和安装对应 skill。
- agent 环境是主安装位置，项目里的 `skills/` 适合镜像、定制和版本管理。
- 优先遵循项目现有约定，其次才是通用最佳实践。
