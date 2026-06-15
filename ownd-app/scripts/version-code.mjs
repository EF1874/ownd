import { fileURLToPath } from 'node:url';

const VERSION_CODE_FACTOR = {
  major: 1_000_000,
  minor: 1_000,
};

export const parseVersionName = (rawVersion) => {
  const versionName = String(rawVersion).split('+')[0].trim();
  const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(versionName);
  if (!match) {
    throw new Error('Version must use major.minor.patch format, for example 2.1.0');
  }

  const [, majorText, minorText, patchText] = match;
  const major = Number(majorText);
  const minor = Number(minorText);
  const patch = Number(patchText);
  if (minor > 999 || patch > 999) {
    throw new Error('Minor and patch versions must be 999 or lower');
  }

  return { major, minor, patch, versionName };
};

export const semanticVersionCode = (rawVersion) => {
  const { major, minor, patch } = parseVersionName(rawVersion);
  return major * VERSION_CODE_FACTOR.major + minor * VERSION_CODE_FACTOR.minor + patch;
};

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    console.log(semanticVersionCode(process.argv[2]));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
