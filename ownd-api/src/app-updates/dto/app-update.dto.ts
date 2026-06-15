import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AppUpdateArtifactDto {
  @ApiProperty({ example: 'arm64-v8a' })
  abi: string;

  @ApiProperty({
    example:
      'https://download.ownd.cc/android/releases/v2.0.5/ownd-android-v2.0.5+205-arm64-v8a.apk',
  })
  apkUrl: string;

  @ApiProperty({ example: 42100000 })
  apkSizeBytes: number;

  @ApiProperty({ example: 'e3b0c44298fc1c149afbf4c8996fb924...' })
  sha256: string;
}

export class AppUpdateDto {
  @ApiProperty({ example: 'android' })
  platform: string;

  @ApiProperty({ example: '2.0.5' })
  version: string;

  @ApiProperty({ example: 205 })
  versionCode: number;

  @ApiProperty({ example: false })
  forceUpdate: boolean;

  @ApiProperty({
    example:
      'https://download.ownd.cc/android/releases/v2.0.5/ownd-android-v2.0.5+205-universal.apk',
  })
  apkUrl: string;

  @ApiProperty({ example: 48234496 })
  apkSizeBytes: number;

  @ApiProperty({ example: 'e3b0c44298fc1c149afbf4c8996fb924...' })
  sha256: string;

  @ApiProperty({ type: [AppUpdateArtifactDto] })
  artifacts: AppUpdateArtifactDto[];

  @ApiProperty({ type: [String], example: ['优化更新体验', '修复已知问题'] })
  releaseNotes: string[];

  @ApiPropertyOptional({ example: '2.0.0' })
  minSupportedVersion?: string;

  @ApiPropertyOptional({ example: '发现新版本' })
  title?: string;

  @ApiPropertyOptional({ example: '2026-06-12T12:00:00.000Z' })
  publishedAt?: string;
}
