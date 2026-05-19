ALTER TABLE "User"
  ADD COLUMN "categoryDefaultsInitialized" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "platformDefaultsInitialized" BOOLEAN NOT NULL DEFAULT false;

UPDATE "User"
SET
  "categoryDefaultsInitialized" = EXISTS (
    SELECT 1 FROM "Category" WHERE "Category"."userId" = "User"."id"
  ),
  "platformDefaultsInitialized" = EXISTS (
    SELECT 1 FROM "Platform" WHERE "Platform"."userId" = "User"."id"
  );
