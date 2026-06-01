import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../app.module';

import { PrismaService } from '../prisma/prisma.service';
import { MinioService } from '../minio/minio.service';

import { ConfigService } from '@nestjs/config';

describe('Swagger (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(ConfigService)
      .useValue({
        get: jest.fn((key: string) => {
          if (key === 'JWT_SECRET') return 'test-secret';
          return null;
        }),
      })
      .overrideProvider(PrismaService)
      .useValue({
        $connect: jest.fn(),
        $disconnect: jest.fn(),
      })
      .overrideProvider(MinioService)
      .useValue({
        initBucket: jest.fn(),
      })
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');

    // 手动在测试环境中配置 Swagger
    const config = new DocumentBuilder()
      .setTitle('Ownd API')
      .setDescription('Ownd API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api-docs', app, document);

    await app.init();
  });

  it('应该能够成功访问 Swagger JSON 路径', () => {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    return request(app.getHttpServer())
      .get('/api-docs-json')
      .expect(200)
      .expect((res: request.Response) => {
        expect(res.body.openapi).toBeDefined();
        expect(res.body.info.title).toBe('Ownd API');
        expect(res.body.info.description).toBeDefined();
      });
  });

  it('应该包含 Auth 相关的安全定义', () => {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    return request(app.getHttpServer())
      .get('/api-docs-json')
      .expect(200)
      .expect((res: request.Response) => {
        const securitySchemes = res.body.components?.securitySchemes;
        expect(securitySchemes).toBeDefined();
        expect(securitySchemes.bearer).toBeDefined();
        expect(securitySchemes.bearer.type).toBe('http');
        expect(securitySchemes.bearer.scheme).toBe('bearer');
      });
  });

  it('应该包含物品管理的 Tags 分组', () => {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    return request(app.getHttpServer())
      .get('/api-docs-json')
      .expect(200)
      .expect((res: request.Response) => {
        const paths = res.body.paths;
        const itemsPostTags =
          (paths['/api/v1/items']?.post?.tags as string[]) || [];
        expect(itemsPostTags).toContain('物品管理');
      });
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });
});
