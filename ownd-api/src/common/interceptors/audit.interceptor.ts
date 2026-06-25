import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { AUDIT_ACTION_KEY } from '../decorators/audit.decorator';
import { sanitize } from '../utils/sanitizer.util';
import { Request } from 'express';
import { User, Prisma } from '@prisma/client';

interface RequestWithUser extends Request {
  user: User;
}

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger(AuditInterceptor.name);

  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const action = this.reflector.get<string>(
      AUDIT_ACTION_KEY,
      context.getHandler(),
    );

    if (!action) {
      return next.handle();
    }

    const request = context.switchToHttp().getRequest<RequestWithUser>();
    const { method, path, user, ip } = request;
    const body = request.body as Record<string, unknown>;

    return next.handle().pipe(
      tap({
        next: () => {
          // 这里的报错通常是由于 IDE 缓存未及时同步 Prisma 生成的客户端代码导致的。
          // 请尝试在 VS Code 中执行 "TypeScript: Restart TS Server" 刷新缓存。
          void this.prisma.auditLog
            .create({
              data: {
                userId: user?.id,
                action,
                method,
                path,
                payload: sanitize(body) as Prisma.InputJsonValue,
                ip,
              },
            })
            .catch((err: Error) => {
              this.logger.error(`审计日志记录失败: ${err.message}`);
            });
        },
      }),
    );
  }
}
