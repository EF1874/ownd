UPDATE "Item" i
SET "isVirtual" = false
WHERE i."isVirtual" = true
  AND i."nextBillingDate" IS NULL
  AND i."currentCycleType" IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM "ItemHistory" ih
    WHERE ih."itemId" = i."id"
  )
  AND NOT EXISTS (
    SELECT 1
    FROM "Category" c
    LEFT JOIN "Category" pc ON pc."id" = c."parentId"
    WHERE c."id" = i."categoryId"
      AND (c."name" = '虚拟订阅' OR pc."name" = '虚拟订阅')
  );
