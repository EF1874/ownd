ALTER TABLE "Item" ADD COLUMN IF NOT EXISTS "hasReminder" BOOLEAN NOT NULL DEFAULT false;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'Item'
      AND column_name = 'reminderDays'
  ) THEN
    UPDATE "Item"
    SET "hasReminder" = "reminderDays" > 0
    WHERE "reminderDays" IS NOT NULL;
  END IF;
END $$;

ALTER TABLE "Item" DROP COLUMN IF EXISTS "reminderDays";
