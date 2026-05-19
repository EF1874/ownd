-- Replace the old user-wide category uniqueness with scope-aware indexes.
DROP INDEX IF EXISTS "Category_name_userId_key";

CREATE INDEX IF NOT EXISTS "Category_name_userId_idx" ON "Category"("name", "userId");

CREATE UNIQUE INDEX IF NOT EXISTS "Category_system_root_name_key"
  ON "Category"("name")
  WHERE "userId" IS NULL AND "parentId" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "Category_system_child_parent_name_key"
  ON "Category"("parentId", "name")
  WHERE "userId" IS NULL AND "parentId" IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "Category_user_root_name_key"
  ON "Category"("userId", "name")
  WHERE "userId" IS NOT NULL AND "parentId" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "Category_user_child_parent_name_key"
  ON "Category"("userId", "parentId", "name")
  WHERE "userId" IS NOT NULL AND "parentId" IS NOT NULL;
