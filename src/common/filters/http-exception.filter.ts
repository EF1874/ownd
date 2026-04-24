import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : null;

    // 处理 NestJS 内置的校验错误（数组形式）
    let message = 'Internal server error';
    if (exception instanceof HttpException) {
      message = exception.message;
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    // 如果是 ValidationPipe 抛出的错误，message 字段通常在 exceptionResponse 中
    if (
      exceptionResponse &&
      typeof exceptionResponse === 'object' &&
      !Array.isArray(exceptionResponse)
    ) {
      const msg = (exceptionResponse as Record<string, unknown>)['message'];
      if (msg) {
        // 如果是个数组，将其扁平化为字符串（满足前端 Toast 需求）
        message = Array.isArray(msg) ? msg.join('; ') : (msg as string);
      }
    }

    const errorResponse = {
      code: status,
      msg: message,
      path: request.url,
      timestamp: new Date().toISOString(),
    };

    response.status(status).json(errorResponse);
  }
}
