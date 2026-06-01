import {
  Injectable,
  ExecutionContext,
  UnauthorizedException,
  Inject,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { ExtractJwt } from 'passport-jwt';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache) {
    super();
  }

  override async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<import('express').Request>();
    const token = ExtractJwt.fromAuthHeaderAsBearerToken()(request);

    if (token) {
      try {
        const isBlacklisted = await this.cacheManager.get<boolean>(
          `blacklist:${token}`,
        );
        if (isBlacklisted) {
          throw new UnauthorizedException('该 Token 已失效，请重新登录');
        }
      } catch {
        // ignore cache errors
      }
    }

    const result = await super.canActivate(context);
    return result as boolean;
  }
}
