WITH candidate_categories AS (
  SELECT
    source."id" AS old_id,
    lower(
      substr(source.hash, 1, 8)
      || '-' || substr(source.hash, 9, 4)
      || '-5' || substr(source.hash, 14, 3)
      || '-8' || substr(source.hash, 18, 3)
      || '-' || substr(source.hash, 21, 12)
    ) AS new_id
  FROM (
    SELECT
      child."id",
      md5('subscription-category-uuid-fix:' || child."id") AS hash
    FROM "Category" AS child
    INNER JOIN "Category" AS parent
      ON parent."id" = child."parentId"
    WHERE parent."name" = '虚拟订阅'
      AND child."id" ~ '^[0-9a-f]{32}$'
  ) AS source
)
UPDATE "Category" AS category
SET "id" = candidate.new_id
FROM candidate_categories AS candidate
WHERE category."id" = candidate.old_id
  AND NOT EXISTS (
    SELECT 1
    FROM "Category" AS existing
    WHERE existing."id" = candidate.new_id
  );
