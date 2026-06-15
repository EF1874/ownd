ALTER TYPE "ItemCycleType" ADD VALUE IF NOT EXISTS 'HALF_YEAR';

CREATE TYPE "ItemCycleCalculationMode" AS ENUM ('CALENDAR', 'FIXED_DAYS');

ALTER TABLE "Item"
ADD COLUMN "firstPeriodPrice" DOUBLE PRECISION,
ADD COLUMN "currentCycleMode" "ItemCycleCalculationMode" NOT NULL DEFAULT 'CALENDAR',
ADD COLUMN "currentCycleDays" INTEGER;

ALTER TABLE "ItemHistory"
ADD COLUMN "cycleMode" "ItemCycleCalculationMode" NOT NULL DEFAULT 'CALENDAR',
ADD COLUMN "cycleDays" INTEGER;
