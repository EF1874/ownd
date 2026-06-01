import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { ItemsModule } from './items/items.module';
import { MinioModule } from './minio/minio.module';
import { CategoriesModule } from './categories/categories.module';
import { LoggerMiddleware } from './common/middleware/logger.middleware';
import { StatisticsModule } from './statistics/statistics.module';
import { PlatformModule } from './platform/platform.module';
import { APP_INTERCEPTOR, APP_GUARD } from '@nestjs/core';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';
import { CacheModule } from '@nestjs/cache-manager';
import { redisStore } from 'cache-manager-redis-yet';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { ThrottlerStorageRedisService } from 'nestjs-throttler-storage-redis';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: `.env.${process.env.NODE_ENV || 'development'}`,
    }),
    CacheModule.registerAsync({
      isGlobal: true,
      useFactory: async (configService: ConfigService) => {
        try {
          const host = configService.get<string>('REDIS_HOST', 'localhost');
          const port = Number(configService.get<string>('REDIS_PORT', '6379'));
          const store = await redisStore({
            socket: {
              host,
              port,
            },
            ttl: 60000,
          });
          return { store };
        } catch (error) {
          console.warn(
            'Redis connection failed, falling back to memory store:',
            error,
          );
          return {};
        }
      },
      inject: [ConfigService],
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const host = configService.get<string>('REDIS_HOST', 'localhost');
        const port = Number(configService.get<string>('REDIS_PORT', '6379'));
        return {
          throttlers: [
            {
              name: 'default',
              ttl: 60000,
              limit: 100,
            },
            {
              name: 'auth',
              ttl: 60000,
              limit: 10,
            },
          ],
          storage: new ThrottlerStorageRedisService({
            host,
            port,
          }),
        };
      },
    }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    ItemsModule,
    MinioModule,
    CategoriesModule,
    StatisticsModule,
    PlatformModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*path');
  }
}
