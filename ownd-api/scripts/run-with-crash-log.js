const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const mode = process.argv[2] || 'dev';
const command = process.argv.slice(3).join(' ');

if (!command) {
  console.error('Missing command to run.');
  process.exit(1);
}

const logsDir = path.join(__dirname, '..', 'logs');
fs.mkdirSync(logsDir, { recursive: true });

const logFile = path.join(logsDir, `service-${mode}.log`);
const crashFile = path.join(logsDir, `service-${mode}-crash.log`);

function timestamp() {
  return new Date().toISOString();
}

function append(file, message) {
  fs.appendFileSync(file, `[${timestamp()}] ${message}\n`, 'utf8');
}

function appendBlock(file, title, value) {
  append(file, title);
  fs.appendFileSync(file, `${value}\n`, 'utf8');
}

function serializeError(error) {
  if (!error) return 'Unknown error';
  if (error instanceof Error) return error.stack || error.message;
  try {
    return JSON.stringify(error, null, 2);
  } catch (_) {
    return String(error);
  }
}

append(logFile, `Starting service (${mode})`);
append(logFile, `Command: ${command}`);
append(logFile, `Working directory: ${process.cwd()}`);
append(logFile, `Node: ${process.version}`);

const child = spawn(command, {
  cwd: path.join(__dirname, '..'),
  env: process.env,
  shell: true,
  windowsHide: false,
});

child.stdout.on('data', (data) => {
  const text = data.toString();
  process.stdout.write(text);
  fs.appendFileSync(logFile, text, 'utf8');
});

child.stderr.on('data', (data) => {
  const text = data.toString();
  process.stderr.write(text);
  fs.appendFileSync(logFile, text, 'utf8');
});

child.on('error', (error) => {
  const detail = serializeError(error);
  appendBlock(crashFile, 'Failed to start child process', detail);
  appendBlock(logFile, 'Failed to start child process', detail);
});

child.on('exit', (code, signal) => {
  const message = `Service exited. code=${code ?? 'none'} signal=${signal ?? 'none'}`;
  append(logFile, message);
  if (code !== 0 || signal) {
    append(crashFile, message);
  }
});

process.on('uncaughtException', (error) => {
  appendBlock(crashFile, 'Launcher uncaught exception', serializeError(error));
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  appendBlock(crashFile, 'Launcher unhandled rejection', serializeError(reason));
});
