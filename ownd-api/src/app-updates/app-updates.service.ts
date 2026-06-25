import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppUpdateArtifactDto, AppUpdateDto } from './dto/app-update.dto';

type UpdateArtifactManifest = {
  abi?: unknown;
  apkUrl?: unknown;
  versionCode?: unknown;
  apkSizeBytes?: unknown;
  sha256?: unknown;
};

type UpdateManifest = {
  platform?: unknown;
  version?: unknown;
  versionCode?: unknown;
  forceUpdate?: unknown;
  apkUrl?: unknown;
  apkSizeBytes?: unknown;
  sha256?: unknown;
  artifacts?: unknown;
  releaseNotes?: unknown;
  minSupportedVersion?: unknown;
  title?: unknown;
  publishedAt?: unknown;
};

@Injectable()
export class AppUpdatesService {
  constructor(private readonly configService: ConfigService) {}

  async getLatest(platform = 'android'): Promise<AppUpdateDto> {
    if (platform !== 'android') {
      throw new BadRequestException('暂不支持此平台的应用更新');
    }

    const manifestUrl = this.configService.get<string>(
      'APP_UPDATE_ANDROID_MANIFEST_URL',
    );
    if (!manifestUrl) {
      throw new ServiceUnavailableException('应用更新服务未配置');
    }

    let response: Response;
    try {
      response = await fetch(manifestUrl, {
        headers: { Accept: 'application/json' },
      });
    } catch {
      throw new ServiceUnavailableException('应用更新信息暂时不可用');
    }

    if (!response.ok) {
      throw new ServiceUnavailableException('应用更新信息暂时不可用');
    }

    let manifest: UpdateManifest;
    try {
      manifest = (await response.json()) as UpdateManifest;
    } catch {
      throw new ServiceUnavailableException('应用更新信息格式错误');
    }

    return this.toAppUpdateDto(manifest);
  }

  private toAppUpdateDto(manifest: UpdateManifest): AppUpdateDto {
    const platform = this.requiredString(manifest.platform, 'platform');
    if (platform !== 'android') {
      throw new ServiceUnavailableException('应用更新平台配置不匹配');
    }

    const versionCode = this.requiredNumber(
      manifest.versionCode,
      'versionCode',
    );
    const artifacts = this.artifacts(manifest, versionCode);
    const defaultArtifact =
      artifacts.find((artifact) => artifact.abi === 'universal') ??
      artifacts[0];

    return {
      platform,
      version: this.requiredString(manifest.version, 'version'),
      versionCode,
      forceUpdate:
        typeof manifest.forceUpdate === 'boolean'
          ? manifest.forceUpdate
          : false,
      apkUrl: defaultArtifact.apkUrl,
      apkSizeBytes: defaultArtifact.apkSizeBytes,
      sha256: defaultArtifact.sha256,
      artifacts,
      releaseNotes: this.stringArray(manifest.releaseNotes),
      minSupportedVersion: this.optionalString(manifest.minSupportedVersion),
      title: this.optionalString(manifest.title),
      publishedAt: this.optionalString(manifest.publishedAt),
    };
  }

  private artifacts(
    manifest: UpdateManifest,
    fallbackVersionCode: number,
  ): AppUpdateArtifactDto[] {
    if (Array.isArray(manifest.artifacts)) {
      const artifacts = manifest.artifacts.map((artifact, index) =>
        this.artifact(artifact, `artifacts[${index}]`, fallbackVersionCode),
      );
      if (artifacts.length > 0) {
        return artifacts;
      }
    }

    return [
      {
        abi: 'universal',
        apkUrl: this.requiredString(manifest.apkUrl, 'apkUrl'),
        versionCode: fallbackVersionCode,
        apkSizeBytes: this.requiredNumber(
          manifest.apkSizeBytes,
          'apkSizeBytes',
        ),
        sha256: this.requiredString(manifest.sha256, 'sha256'),
      },
    ];
  }

  private artifact(
    value: unknown,
    field: string,
    fallbackVersionCode: number,
  ): AppUpdateArtifactDto {
    if (!value || typeof value !== 'object') {
      throw new ServiceUnavailableException('应用更新配置不完整，请稍后再试');
    }

    const artifact = value as UpdateArtifactManifest;
    return {
      abi: this.requiredString(artifact.abi, `${field}.abi`),
      apkUrl: this.requiredString(artifact.apkUrl, `${field}.apkUrl`),
      versionCode:
        artifact.versionCode === undefined
          ? fallbackVersionCode
          : this.requiredNumber(artifact.versionCode, `${field}.versionCode`),
      apkSizeBytes: this.requiredNumber(
        artifact.apkSizeBytes,
        `${field}.apkSizeBytes`,
      ),
      sha256: this.requiredString(artifact.sha256, `${field}.sha256`),
    };
  }

  private requiredString(value: unknown, _field: string): string {
    if (typeof value === 'string' && value.trim().length > 0) {
      return value;
    }

    throw new ServiceUnavailableException('应用更新配置不完整，请稍后再试');
  }

  private optionalString(value: unknown): string | undefined {
    if (typeof value === 'string' && value.trim().length > 0) {
      return value;
    }

    return undefined;
  }

  private requiredNumber(value: unknown, _field: string): number {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }

    throw new ServiceUnavailableException('应用更新配置不完整，请稍后再试');
  }

  private stringArray(value: unknown): string[] {
    if (!Array.isArray(value)) {
      return [];
    }

    return value.filter((item): item is string => typeof item === 'string');
  }
}
