# Acceptance

> 中文建议：记录验收范围、发现、剩余风险和是否建议发布。

## Scope Under Review

- 范围：V4 进入实施前的质量收敛关口（R1-R6）
- 目标：在继续 TSK-4.2~4.5 之前，确保契约、质量门、鉴权、迁移策略均可验证
- 本次追加范围：Flutter Android app 在线优先 API 迁移第一批（认证、网络层、Items、Categories）。

## Verification Checklist

- [x] R1：API 响应协议已统一为 `code/data/msg`，并同步文档
- [x] R2：图片上传路径参数顺序问题已修复并补测试
- [x] R3：`npm run lint` 无错误
- [x] R4：JWT 校验主路径为 `sub(id)` 查询
- [x] R5：MinIO 缺失关键配置时 fail-fast
- [x] R6：周期字段输入校验增强并通过测试
- [x] 后端 `npm run lint` / `npm run build` / `npx jest --runInBand --detectOpenHandles --forceExit` / `npx prisma validate` 全部通过
- [x] Flutter `flutter analyze` 无问题
- [x] Flutter Android debug APK 构建通过
- [ ] Flutter 无自动化测试文件，主流程仍需真机/模拟器人工联调验证

## Findings

- 后端 `lint/build` 通过；Jest 共 11 个测试套件、47 个测试通过；Prisma schema valid。
- 原始 `npm run test` 在本地表现为长时间无输出，使用 `--runInBand --detectOpenHandles --forceExit` 可完成测试。
- Flutter 已接入在线优先 API：认证会话、Token 注入、Items 远程 DataSource、Categories 远程 DataSource。
- 仍需后续补齐图片远程访问、Platform/History/Statistics 的完整 UI 迁移和 Flutter 自动化测试。

## Release Recommendation

- 后端质量关口可作为 app 第一批迁移基础。
- App 已可进入 Android 模拟器/真机联调；发布前仍需补充 Flutter 测试与图片访问方案。
