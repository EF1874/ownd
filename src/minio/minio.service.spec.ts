import { Test, TestingModule } from '@nestjs/testing';
import { MinioService } from './minio.service';
import { ConfigService } from '@nestjs/config';

// 模拟 Minio 客户端的类型定义，避免使用 any
type MockMinioClient = {
  bucketExists: jest.Mock;
  makeBucket: jest.Mock;
  putObject: jest.Mock;
};

jest.mock('minio', () => {
  return {
    Client: jest.fn().mockImplementation(() => ({
      bucketExists: jest.fn(),
      makeBucket: jest.fn(),
      putObject: jest.fn(),
    })),
  };
});

describe('MinioService', () => {
  let service: MinioService;
  let client: MockMinioClient;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MinioService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === 'MINIO_ENDPOINT') return 'localhost';
              if (key === 'MINIO_ROOT_USER') return 'admin';
              if (key === 'MINIO_ROOT_PASSWORD') return 'password';
              return null;
            }),
          },
        },
      ],
    }).compile();

    service = module.get<MinioService>(MinioService);
    client = (service as any).client as MockMinioClient;
  });

  it('应该能够成功初始化桶 (如果不存在则创建)', async () => {
    client.bucketExists.mockResolvedValue(false);
    client.makeBucket.mockResolvedValue(undefined);

    await service.initBucket();

    expect(client.bucketExists).toHaveBeenCalled();
    expect(client.makeBucket).toHaveBeenCalledWith('ownd-items');
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
    expect(path).toContain('test.png');
  });
});
