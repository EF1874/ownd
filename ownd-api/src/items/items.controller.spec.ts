import { Test, TestingModule } from '@nestjs/testing';
import { ItemsController } from './items.controller';
import { ItemsService } from './items.service';
import { MinioService } from '../minio/minio.service';
import { AssetsService } from '../assets/assets.service';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { AssetPurpose, User } from '@prisma/client';
import { Readable } from 'stream';
import type { Response } from 'express';

describe('ItemsController', () => {
  let controller: ItemsController;
  let service: DeepMockProxy<ItemsService>;
  let minioService: DeepMockProxy<MinioService>;
  let assetsService: DeepMockProxy<AssetsService>;

  const mockUser: User = {
    id: 'user-1',
    email: 'test@test.com',
    name: 'Test User',
    password: 'hashedpassword',
    avatarPath: null,
    categoryDefaultsInitialized: false,
    platformDefaultsInitialized: false,
    notificationLeadDays: 3,
    notificationTime: '08:00',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  type ControllerRequest = Parameters<ItemsController['create']>[1];
  type ControllerItem = Awaited<ReturnType<ItemsService['findOne']>>;
  const mockRequest = { user: mockUser } as unknown as ControllerRequest;
  const mockItem = (id: string, imagePath: string | null): ControllerItem =>
    ({ id, userId: mockUser.id, imagePath }) as unknown as ControllerItem;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ItemsController],
      providers: [
        {
          provide: ItemsService,
          useValue: mockDeep<ItemsService>(),
        },
        {
          provide: MinioService,
          useValue: mockDeep<MinioService>(),
        },
        {
          provide: AssetsService,
          useValue: mockDeep<AssetsService>(),
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<ItemsController>(ItemsController);
    service = module.get(ItemsService);
    minioService = module.get(MinioService);
    assetsService = module.get(AssetsService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('应该调用 service.create 并传入正确的 userId', async () => {
      const dto: CreateItemDto = { name: '物品', price: 10 };
      await controller.create(dto, mockRequest);

      expect(service.create.mock.calls[0]).toEqual([mockUser.id, dto]);
    });
  });

  describe('findAll', () => {
    it('应该调用 service.findAll 并传入正确的 userId', async () => {
      await controller.findAll(mockRequest);

      expect(service.findAll.mock.calls[0]).toEqual([
        mockUser.id,
        {
          search: undefined,
          page: undefined,
          limit: undefined,
          categoryId: undefined,
          platformId: undefined,
          expiringSoon: false,
          status: undefined,
          tag: undefined,
          sortBy: undefined,
          sortOrder: undefined,
        },
      ]);
    });
  });

  describe('findOne', () => {
    it('应该传入正确的 itemId 和 userId', async () => {
      const itemId = 'item-123';
      await controller.findOne(itemId, mockRequest);

      expect(service.findOne.mock.calls[0]).toEqual([mockUser.id, itemId]);
    });
  });

  describe('update', () => {
    it('应该传入正确的参数进行更新', async () => {
      const itemId = 'item-123';
      const dto: UpdateItemDto = { name: '新名字' };
      await controller.update(itemId, dto, mockRequest);

      expect(service.update.mock.calls[0]).toEqual([mockUser.id, itemId, dto]);
    });
  });

  describe('remove', () => {
    it('应该调用 service.remove 并传入正确的 ID', async () => {
      const itemId = 'item-123';
      const imagePath = '/ownd-items/test.png';
      service.findOne.mockResolvedValue(mockItem(itemId, imagePath));

      await controller.remove(itemId, mockRequest);

      expect(service.findOne.mock.calls[0]).toEqual([mockUser.id, itemId]);
      expect(service.remove.mock.calls[0]).toEqual([mockUser.id, itemId]);
      expect(assetsService.releasePath.mock.calls[0]?.[0]).toBe(imagePath);
    });
  });

  describe('uploadImage', () => {
    it('应该经过 权限校验 -> MinIO 上传 -> 资产登记 -> 数据库更新 的完整流程', async () => {
      const itemId = 'item-123';
      const mockFile = {
        originalname: 'test.png',
        buffer: Buffer.from('test'),
        mimetype: 'image/png',
        size: 4,
      } as Express.Multer.File;
      const oldImagePath = '/ownd-items/old.png';
      const mockSavedPath = '/ownd-items/test.png';

      service.findOne.mockResolvedValue(mockItem(itemId, oldImagePath));
      minioService.uploadFile.mockResolvedValue(mockSavedPath);

      await controller.uploadImage(itemId, mockFile, mockRequest);

      expect(service.findOne.mock.calls[0]).toEqual([mockUser.id, itemId]);
      expect(minioService.uploadFile.mock.calls[0]?.[0]).toBe(mockFile);
      expect(assetsService.registerUpload.mock.calls[0]?.[0]).toEqual({
        userId: mockUser.id,
        path: mockSavedPath,
        purpose: AssetPurpose.ITEM_IMAGE,
        file: mockFile,
      });
      expect(service.updateImagePath.mock.calls[0]).toEqual([
        mockUser.id,
        itemId,
        mockSavedPath,
      ]);
      expect(assetsService.releasePath.mock.calls[0]?.[0]).toBe(oldImagePath);
    });

    it('数据库更新失败时应该丢弃刚上传的图片', async () => {
      const itemId = 'item-123';
      const mockFile = {
        originalname: 'test.png',
        buffer: Buffer.from('test'),
        mimetype: 'image/png',
        size: 4,
      } as Express.Multer.File;
      const mockSavedPath = '/ownd-items/test.png';
      const error = new Error('update failed');

      service.findOne.mockResolvedValue(mockItem(itemId, null));
      minioService.uploadFile.mockResolvedValue(mockSavedPath);
      service.updateImagePath.mockRejectedValue(error);

      await expect(
        controller.uploadImage(itemId, mockFile, mockRequest),
      ).rejects.toThrow(error);

      expect(assetsService.discardUpload.mock.calls[0]?.[0]).toBe(
        mockSavedPath,
      );
    });
  });

  describe('removeImage', () => {
    it('应该删除图片文件并清空物品图片路径', async () => {
      const itemId = 'item-123';
      const imagePath = '/ownd-items/test.png';
      service.findOne.mockResolvedValue(mockItem(itemId, imagePath));

      await controller.removeImage(itemId, mockRequest);

      expect(service.findOne.mock.calls[0]).toEqual([mockUser.id, itemId]);
      expect(service.updateImagePath.mock.calls[0]).toEqual([
        mockUser.id,
        itemId,
        null,
      ]);
      expect(assetsService.releasePath.mock.calls[0]?.[0]).toBe(imagePath);
    });
  });

  describe('getImage', () => {
    it('应该从 MinIO 读取图片并写入响应', async () => {
      const stream = Readable.from(['image']);
      const setHeader = jest.fn();
      const res = {
        setHeader,
      } as unknown as Response;
      const pipeSpy = jest
        .spyOn(stream, 'pipe')
        .mockImplementation((destination) => destination);
      minioService.getFile.mockResolvedValue({
        stream,
        contentType: 'image/png',
      });

      await controller.getImage('test.png', res);

      expect(minioService.getFile.mock.calls[0]?.[0]).toBe('test.png');
      expect(setHeader.mock.calls).toContainEqual([
        'Content-Type',
        'image/png',
      ]);
      expect(pipeSpy.mock.calls[0]?.[0]).toBe(res);
    });
  });
});
