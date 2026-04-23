/*
  Warnings:

  - You are about to drop the column `isDestroyed` on the `Item` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Item" DROP COLUMN "isDestroyed",
ADD COLUMN     "backupDate" TIMESTAMP(3),
ADD COLUMN     "isScrapped" BOOLEAN DEFAULT false,
ADD COLUMN     "scrappedDate" TIMESTAMP(3),
ADD COLUMN     "warrantyEndDate" TIMESTAMP(3);
