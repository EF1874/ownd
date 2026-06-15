import { fileURLToPath } from 'node:url';

export const parseVersionName = (rawVersion) => {
  const versionName = String(rawVersion).split('+')[0].trim();
  const match = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.exec(
    versionName,
  );
  if (!match) {
    throw new Error(
      'Version must use major.minor.patch format, for example 2.1.0',
    );
  }

  const [, majorText, minorText, patchText] = match;
  return {
    major: Number(majorText),
    minor: Number(minorText),
    patch: Number(patchText),
    versionName,
  };
};

export const parseAppVersion = (rawVersion) => {
  const appVersion = String(rawVersion).trim();
  const [versionName, buildNumber] = appVersion.split('+');
  parseVersionName(versionName);

  if (!/^[1-9]\d*$/.test(buildNumber ?? '')) {
    throw new Error(
      'Version must include a positive build number, for example 2.1.0+210',
    );
  }

  return {
    versionName,
    buildNumber: Number(buildNumber),
  };
};

export const compareVersionNames = (leftVersion, rightVersion) => {
  const left = parseVersionName(leftVersion);
  const right = parseVersionName(rightVersion);
  for (const key of ['major', 'minor', 'patch']) {
    if (left[key] > right[key]) return 1;
    if (left[key] < right[key]) return -1;
  }

  return 0;
};

export const nextBuildNumber = (currentBuildNumber, fallbackBuildNumber) => {
  const current = Number(currentBuildNumber);
  const fallback = Number(fallbackBuildNumber);
  if (!Number.isInteger(fallback) || fallback <= 0) {
    throw new Error('Fallback build number must be a positive integer');
  }
  if (!Number.isInteger(current) || current <= 0) {
    return fallback;
  }

  return Math.max(current + 1, fallback);
};

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    const [, , command, ...args] = process.argv;
    if (command === 'validate-version') {
      console.log(parseVersionName(args[0]).versionName);
    } else if (command === 'validate-app-version') {
      const version = parseAppVersion(args[0]);
      console.log(`${version.versionName}+${version.buildNumber}`);
    } else if (command === 'compare') {
      console.log(compareVersionNames(args[0], args[1]));
    } else if (command === 'next-build-number') {
      console.log(nextBuildNumber(args[0], args[1]));
    } else {
      throw new Error(
        'Usage: version-code.mjs <validate-version|validate-app-version|compare|next-build-number> ...',
      );
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
