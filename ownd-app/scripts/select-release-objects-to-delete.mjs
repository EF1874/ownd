#!/usr/bin/env node

const args = new Map();
for (let index = 2; index < process.argv.length; index += 2) {
  args.set(process.argv[index], process.argv[index + 1]);
}

const latestKey = args.get('--latest-key');
const retentionDays = Number(args.get('--retention-days') ?? 7);
const maxVersions = Number(args.get('--max-versions') ?? 5);

if (!latestKey) {
  throw new Error('Missing required argument: --latest-key');
}

const input = await readStdin();
const payload = JSON.parse(input || '{}');
const contents = Array.isArray(payload.Contents) ? payload.Contents : [];
const latestVersion = extractVersion(latestKey);
const cutoff = Date.now() - retentionDays * 24 * 60 * 60 * 1000;

const versions = new Map();
for (const object of contents) {
  if (typeof object.Key !== 'string') continue;
  const version = extractVersion(object.Key);
  if (!version) continue;

  const modifiedAt = Date.parse(object.LastModified ?? '');
  const existing = versions.get(version) ?? {
    version,
    latestModifiedAt: 0,
    keys: [],
  };
  existing.latestModifiedAt = Math.max(
    existing.latestModifiedAt,
    Number.isFinite(modifiedAt) ? modifiedAt : 0,
  );
  existing.keys.push(object.Key);
  versions.set(version, existing);
}

const recentVersions = [...versions.values()]
  .filter((version) => version.latestModifiedAt >= cutoff)
  .sort((left, right) => right.latestModifiedAt - left.latestModifiedAt)
  .slice(0, maxVersions)
  .map((version) => version.version);

const keepVersions = new Set(recentVersions);
if (latestVersion) {
  keepVersions.add(latestVersion);
}

const deleteKeys = [...versions.values()]
  .filter((version) => !keepVersions.has(version.version))
  .flatMap((version) => version.keys)
  .sort();

process.stdout.write(
  JSON.stringify({
    Objects: deleteKeys.map((Key) => ({ Key })),
    Quiet: true,
  }),
);

function extractVersion(key) {
  const match = key.match(/^android\/releases\/([^/]+)\//);
  return match?.[1];
}

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => {
      data += chunk;
    });
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}
