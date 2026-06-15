import { mkdirSync, appendFileSync } from 'fs';
import { join } from 'path';

const logsDir = join(process.cwd(), 'logs');
const crashLogPath = join(logsDir, 'process-crash.log');

const serializeError = (error: unknown) => {
  if (error instanceof Error) {
    return error.stack ?? error.message;
  }

  try {
    return JSON.stringify(error, null, 2);
  } catch {
    return String(error);
  }
};

export const appendProcessCrashLog = (title: string, error: unknown) => {
  mkdirSync(logsDir, { recursive: true });
  appendFileSync(
    crashLogPath,
    `[${new Date().toISOString()}] ${title}\n${serializeError(error)}\n`,
    'utf8',
  );
};

export const registerProcessCrashLogger = () => {
  process.on('uncaughtException', (error) => {
    appendProcessCrashLog('uncaughtException', error);
  });

  process.on('unhandledRejection', (reason) => {
    appendProcessCrashLog('unhandledRejection', reason);
  });
};
