import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Response, Request } from 'express';
import { ConfigService } from '@nestjs/config';

@Catch(Prisma.PrismaClientKnownRequestError, Prisma.PrismaClientValidationError)
export class PrismaClientExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaClientExceptionFilter.name);

  // 注入 ConfigService
  constructor(private readonly configService: ConfigService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let customMessage = '数据库操作失败';
    let rawMessage = 'An unexpected database error occurred';

    // 类型守卫：处理验证错误
    if (exception instanceof Prisma.PrismaClientValidationError) {
      status = HttpStatus.BAD_REQUEST;
      customMessage = '请求参数格式错误，请检查输入字段';
      rawMessage = exception.message;
    }
    // 类型守卫：处理已知请求错误
    else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      rawMessage = exception.message;
      switch (exception.code) {
        case 'P2002': {
          status = HttpStatus.CONFLICT;
          const target = (exception.meta?.target as string[]) || ['未知字段'];
          customMessage = `字段冲突: ${target.join(', ')}`;
          break;
        }
        case 'P2025':
          status = HttpStatus.NOT_FOUND;
          customMessage = '请求的资源不存在或无权操作';
          break;
        case 'P2003':
          status = HttpStatus.BAD_REQUEST;
          customMessage = '外键关联错误，请检查关联 ID 是否正确';
          break;
        default:
          customMessage = `数据库错误 (${exception.code})`;
          break;
      }
    } else if (exception instanceof Error) {
      rawMessage = exception.message;
    }

    const env = this.configService.get<string>('NODE_ENV', 'development');
    const isDev = env !== 'production';

    // 服务端日志记录
    this.logger.error(`[${env}] Prisma Exception: ${rawMessage}`);

    response.status(status).json({
      code: status,
      // 开发环境下透传详细的 rawMessage
      message: isDev ? rawMessage : customMessage,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
