/*
  Warnings:

  - Made the column `isAutoRenew` on table `Item` required. This step will fail if there are existing NULL values in that column.
  - Made the column `isBackup` on table `Item` required. This step will fail if there are existing NULL values in that column.
  - Made the column `isScrapped` on table `Item` required. This step will fail if there are existing NULL values in that column.

*/
-- Backfill NULL values
UPDATE "Item" SET "isAutoRenew" = false WHERE "isAutoRenew" IS NULL;
UPDATE "Item" SET "isBackup" = false WHERE "isBackup" IS NULL;
UPDATE "Item" SET "isScrapped" = false WHERE "isScrapped" IS NULL;

-- AlterTable
ALTER TABLE "Item" ALTER COLUMN "isAutoRenew" SET NOT NULL,
ALTER COLUMN "isBackup" SET NOT NULL,
ALTER COLUMN "isScrapped" SET NOT NULL;
