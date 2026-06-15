ALTER TABLE "ItemHistory"
ADD COLUMN "isAutoRenew" BOOLEAN NOT NULL DEFAULT false;

UPDATE "ItemHistory"
SET "isAutoRenew" = true
WHERE "note" LIKE '自动续费%';
