import { Test, TestingModule } from '@nestjs/testing';
import { AssetPurpose, AssetStatus } from '@prisma/client';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { MinioService } from '../minio/minio.service';
import { PrismaService } from '../prisma/prisma.service';
import { AssetsService } from './assets.service';

describe('AssetsService', () => {
  let service: AssetsService;
  let prisma: DeepMockProxy<PrismaService>;
  let minioService: DeepMockProxy<MinioService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AssetsService,
        {
          provide: PrismaService,
          useValue: mockDeep<PrismaService>(),
        },
        {
          provide: MinioService,
          useValue: mockDeep<MinioService>(),
        },
      ],
    }).compile();

    service = module.get<AssetsService>(AssetsService);
    prisma = module.get(PrismaService);
    minioService = module.get(MinioService);
  });

  it('上传后应该先登记为孤儿资产', async () => {
    const file = {
      mimetype: 'image/png',
      size: 4,
    } as Express.Multer.File;

    await service.registerUpload({
      userId: 'user-1',
      path: '/ownd-items/test.png',
      purpose: AssetPurpose.ITEM_IMAGE,
      file,
    });

    expect(prisma.asset.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-1',
        path: '/ownd-items/test.png',
        purpose: AssetPurpose.ITEM_IMAGE,
        status: AssetStatus.ORPHAN,
        mimeType: 'image/png',
        size: 4,
      },
    });
  });

  it('释放资产时应该标记孤儿并删除文件和资产记录', async () => {
    await service.releasePath('/ownd-items/test.png');

    expect(prisma.asset.updateMany).toHaveBeenCalledWith({
      where: { path: '/ownd-items/test.png' },
      data: {
        status: AssetStatus.ORPHAN,
        refType: null,
        refId: null,
      },
    });
    expect(minioService.deleteFile).toHaveBeenCalledWith(
      '/ownd-items/test.png',
    );
    expect(prisma.asset.deleteMany).toHaveBeenCalledWith({
      where: { path: '/ownd-items/test.png' },
    });
  });

  it('定时清理应该只处理超时孤儿资产', async () => {
    prisma.asset.findMany.mockResolvedValue([
      {
        id: 'asset-1',
        path: '/ownd-items/orphan.png',
        userId: 'user-1',
        purpose: AssetPurpose.ITEM_IMAGE,
        status: AssetStatus.ORPHAN,
        refType: null,
        refId: null,
        mimeType: 'image/png',
        size: 4,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);

    await service.cleanupOrphans();

    expect(prisma.asset.findMany).toHaveBeenCalledWith({
      where: {
        status: AssetStatus.ORPHAN,
        updatedAt: { lt: expect.any(Date) },
      },
      take: 200,
      orderBy: { updatedAt: 'asc' },
    });
    expect(minioService.deleteFile).toHaveBeenCalledWith(
      '/ownd-items/orphan.png',
    );
  });
});
