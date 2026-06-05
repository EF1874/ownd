import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(scriptDir, '..');

const [, , platform, env = 'dev', mode = env === 'prod' ? 'release' : 'debug'] =
  process.argv;

const buildCommands = {
  android: {
    debug: ['build', 'apk', '--debug'],
    release: ['build', 'apk', '--release'],
    profile: ['build', 'apk', '--profile'],
  },
  'android:aab': {
    release: ['build', 'appbundle', '--release'],
  },
  ios: {
    debug: ['build', 'ios', '--debug'],
    release: ['build', 'ios', '--release'],
    profile: ['build', 'ios', '--profile'],
  },
  windows: {
    release: ['build', 'windows', '--release'],
  },
  macos: {
    release: ['build', 'macos', '--release'],
  },
  linux: {
    release: ['build', 'linux', '--release'],
  },
};

const printUsage = () => {
  console.log(`Usage: node scripts/build.mjs <platform> [env] [mode]

Examples:
  node scripts/build.mjs android dev debug
  node scripts/build.mjs android prod release
  node scripts/build.mjs android:aab prod release
  node scripts/build.mjs ios prod release
  node scripts/build.mjs windows prod release
`);
};

if (!platform || !buildCommands[platform]?.[mode]) {
  printUsage();
  process.exit(1);
}

let configPath = join(projectRoot, 'config', `${env}.json`);
if (env === 'dev') {
  const localConfigPath = join(projectRoot, 'config', 'local.json');
  if (existsSync(localConfigPath)) {
    configPath = localConfigPath;
    console.log(`[IP Injector] Using dynamically detected local config: config/local.json`);
  }
}

if (!existsSync(configPath)) {
  console.error(`Missing config file: ${configPath}`);
  process.exit(1);
}

const config = JSON.parse(readFileSync(configPath, 'utf8'));

const dartDefines = Object.entries(config).flatMap(([key, value]) => [
  '--dart-define',
  `${key}=${value}`,
]);

const run = (command, args) => {
  const result = spawnSync(command, args, {
    cwd: projectRoot,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
};

run('flutter', ['pub', 'get']);
run('flutter', [...buildCommands[platform][mode], ...dartDefines]);
