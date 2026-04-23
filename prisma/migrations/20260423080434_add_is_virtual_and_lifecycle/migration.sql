-- AlterTable
ALTER TABLE "Category" ADD COLUMN     "isVirtual" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "Item" ADD COLUMN     "isVirtual" BOOLEAN NOT NULL DEFAULT false;
