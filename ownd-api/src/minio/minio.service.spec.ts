import { Test, TestingModule } from '@nestjs/testing';
import { MinioService } from './minio.service';
import { ConfigService } from '@nestjs/config';

// 模拟 Minio 客户端的类型定义，避免使用 any
type MockMinioClient = {
  bucketExists: jest.Mock;
  makeBucket: jest.Mock;
  putObject: jest.Mock;
  removeObject: jest.Mock;
};
let mockMinioClient: MockMinioClient;

jest.mock('minio', () => {
  return {
    Client: jest.fn().mockImplementation(() => {
      mockMinioClient = {
        bucketExists: jest.fn(),
        makeBucket: jest.fn(),
        putObject: jest.fn(),
        removeObject: jest.fn(),
      };
      return mockMinioClient;
    }),
  };
});

describe('MinioService', () => {
  let service: MinioService;
  let client: MockMinioClient;

  const createConfigServiceMock = (
    overrides: Partial<{
      MINIO_ENDPOINT: string | null;
      MINIO_ROOT_USER: string | null;
      MINIO_ROOT_PASSWORD: string | null;
    }> = {},
  ) => ({
    get: jest.fn((key: string) => {
      const configMap: Record<string, string | null> = {
        MINIO_ENDPOINT: 'localhost',
        MINIO_ROOT_USER: 'admin',
        MINIO_ROOT_PASSWORD: 'password',
        ...overrides,
      };
      return key in configMap ? configMap[key] : null;
    }),
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MinioService,
        {
          provide: ConfigService,
          useValue: createConfigServiceMock(),
        },
      ],
    }).compile();

    service = module.get<MinioService>(MinioService);
    client = mockMinioClient;
  });

  it('缺失关键配置时应 fail-fast 抛错', async () => {
    await expect(
      Test.createTestingModule({
        providers: [
          MinioService,
          {
            provide: ConfigService,
            useValue: createConfigServiceMock({ MINIO_ENDPOINT: null }),
          },
        ],
      }).compile(),
    ).rejects.toThrow('Missing MinIO config: MINIO_ENDPOINT');
  });

  it('应该能够成功初始化桶 (如果不存在则创建)', async () => {
    client.bucketExists.mockResolvedValue(false);
    client.makeBucket.mockResolvedValue(undefined);

    await service.initBucket();

    expect(client.bucketExists).toHaveBeenCalled();
    expect(client.makeBucket).toHaveBeenCalledWith('ownd-items');
  });

  it('初始化桶失败时应该向上抛出异常', async () => {
    const initError = new Error('bucket init failed');
    client.bucketExists.mockRejectedValue(initError);

    await expect(service.initBucket()).rejects.toThrow(initError);
  });

  it('健康检查成功时应返回 true', async () => {
    client.bucketExists.mockResolvedValue(true);

    await expect(service.checkHealth()).resolves.toBe(true);
  });

  it('健康检查失败时应向上抛出异常', async () => {
    const healthError = new Error('health check failed');
    client.bucketExists.mockRejectedValue(healthError);

    await expect(service.checkHealth()).rejects.toThrow(healthError);
  });

  it('上传文件时应该调用 putObject 并返回路径', async () => {
    const mockFile = {
      originalname: 'test.png',
      buffer: Buffer.from('test'),
      size: 4,
      mimetype: 'image/png',
    } as Express.Multer.File;

    client.putObject.mockResolvedValue(undefined);

    const path = await service.uploadFile(mockFile);

    expect(client.putObject).toHaveBeenCalled();
    expect(path).toContain('ownd-items');
    expect(path.endsWith('.png')).toBe(true);
  });

  it('删除已上传图片时应该只删除桶内文件', async () => {
    client.removeObject.mockResolvedValue(undefined);

    await service.deleteFile('/ownd-items/test.png');

    expect(client.removeObject).toHaveBeenCalledWith('ownd-items', 'test.png');
  });
});
