CREATE TYPE "AssetPurpose" AS ENUM ('ITEM_IMAGE', 'USER_AVATAR');
CREATE TYPE "AssetStatus" AS ENUM ('ACTIVE', 'ORPHAN');
CREATE TYPE "AssetRefType" AS ENUM ('ITEM', 'USER');

CREATE TABLE "Asset" (
  "id" TEXT NOT NULL,
  "path" TEXT NOT NULL,
  "mimeType" TEXT,
  "size" INTEGER,
  "purpose" "AssetPurpose" NOT NULL,
  "status" "AssetStatus" NOT NULL DEFAULT 'ORPHAN',
  "refType" "AssetRefType",
  "refId" TEXT,
  "userId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "Asset_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Asset_path_key" ON "Asset"("path");
CREATE INDEX "Asset_userId_purpose_status_idx" ON "Asset"("userId", "purpose", "status");
CREATE INDEX "Asset_refType_refId_idx" ON "Asset"("refType", "refId");
CREATE INDEX "Asset_status_updatedAt_idx" ON "Asset"("status", "updatedAt");

ALTER TABLE "Asset"
  ADD CONSTRAINT "Asset_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

INSERT INTO "Asset" (
  "id",
  "path",
  "purpose",
  "status",
  "refType",
  "refId",
  "userId",
  "createdAt",
  "updatedAt"
)
SELECT
  "id",
  "imagePath",
  'ITEM_IMAGE',
  'ACTIVE',
  'ITEM',
  "id",
  "userId",
  "createdAt",
  "updatedAt"
FROM "Item"
WHERE "imagePath" IS NOT NULL
ON CONFLICT ("path") DO NOTHING;
