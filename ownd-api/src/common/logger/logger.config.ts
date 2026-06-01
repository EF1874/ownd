import * as winston from 'winston';
import { utilities as nestWinstonModuleUtilities } from 'nest-winston';
import DailyRotateFile from 'winston-daily-rotate-file';

// 敏感字段脱敏逻辑
const maskFormat = winston.format((info) => {
  const sensitiveFields = ['password', 'token', 'secret', 'authorization'];
  const message = info.message as Record<string, any>;

  if (message && typeof message === 'object') {
    sensitiveFields.forEach((field) => {
      if (message[field]) {
        message[field] = '***MASKED***';
      }
    });
  }
  return info;
});

export const winstonConfig = {
  transports: [
    // 1. 控制台输出 (开发环境友好)
    new winston.transports.Console({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.ms(),
        nestWinstonModuleUtilities.format.nestLike('Ownd', {
          colors: true,
          prettyPrint: true,
        }),
      ),
    }),

    // 2. 错误日志文件 (按天滚动)
    new DailyRotateFile({
      level: 'error',
      dirname: 'logs',
      filename: 'error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '30d',
      format: winston.format.combine(
        winston.format.timestamp(),
        maskFormat(),
        winston.format.json(),
      ),
    }),

    // 3. 全量日志文件 (包含 info 及以上)
    new DailyRotateFile({
      level: 'info',
      dirname: 'logs',
      filename: 'combined-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '14d',
      format: winston.format.combine(
        winston.format.timestamp(),
        maskFormat(),
        winston.format.json(),
      ),
    }),
  ],
};
