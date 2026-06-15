import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AppUpdatesService } from './app-updates.service';

describe('AppUpdatesService', () => {
  let service: AppUpdatesService;
  const fetchMock = jest.fn();

  const manifest = {
    platform: 'android',
    version: '2.0.5',
    versionCode: 205,
    forceUpdate: false,
    apkUrl:
      'https://download.ownd.cc/android/releases/v2.0.5/ownd-android-v2.0.5+205-universal.apk',
    apkSizeBytes: 123456,
    sha256: 'abc123',
    artifacts: [
      {
        abi: 'arm64-v8a',
        apkUrl:
          'https://download.ownd.cc/android/releases/v2.0.5/ownd-android-v2.0.5+205-arm64-v8a.apk',
        versionCode: 2205,
        apkSizeBytes: 42100000,
        sha256: 'arm64abc',
      },
      {
        abi: 'universal',
        apkUrl:
          'https://download.ownd.cc/android/releases/v2.0.5/ownd-android-v2.0.5+205-universal.apk',
        versionCode: 205,
        apkSizeBytes: 123456,
        sha256: 'abc123',
      },
    ],
    releaseNotes: ['优化更新体验'],
    publishedAt: '2026-06-12T12:00:00.000Z',
  };

  const createService = async (
    manifestUrl: string | null = 'https://example.com/latest.json',
  ) => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppUpdatesService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) =>
              key === 'APP_UPDATE_ANDROID_MANIFEST_URL' ? manifestUrl : null,
            ),
          },
        },
      ],
    }).compile();

    return module.get<AppUpdatesService>(AppUpdatesService);
  };

  beforeEach(async () => {
    jest.resetAllMocks();
    global.fetch = fetchMock as unknown as typeof fetch;
    service = await createService();
  });

  it('返回最新 Android 更新信息', async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue(manifest),
    });

    await expect(service.getLatest('android')).resolves.toEqual(manifest);
    expect(fetchMock).toHaveBeenCalledWith('https://example.com/latest.json', {
      headers: { Accept: 'application/json' },
    });
  });

  it('兼容旧版单 APK manifest', async () => {
    const legacyManifest = { ...manifest, artifacts: undefined };
    fetchMock.mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue(legacyManifest),
    });

    await expect(service.getLatest('android')).resolves.toEqual({
      ...legacyManifest,
      artifacts: [
        {
          abi: 'universal',
          apkUrl: legacyManifest.apkUrl,
          versionCode: legacyManifest.versionCode,
          apkSizeBytes: legacyManifest.apkSizeBytes,
          sha256: legacyManifest.sha256,
        },
      ],
    });
  });

  it('不支持非 Android 平台', async () => {
    await expect(service.getLatest('ios')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('缺少 manifest URL 时返回服务不可用', async () => {
    service = await createService(null);

    await expect(service.getLatest('android')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('manifest 缺少必要字段时返回服务不可用', async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue({
        ...manifest,
        artifacts: [{ ...manifest.artifacts[0], sha256: undefined }],
      }),
    });

    await expect(service.getLatest('android')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
