ALTER TABLE "Item" ADD COLUMN "reminderDays" INTEGER NOT NULL DEFAULT 0;

WITH subscription_templates(name, icon) AS (
  VALUES
    ('共享单车月卡', 'MdiIcons.bicycle'),
    ('公交/地铁月票', 'MdiIcons.cardBulleted'),
    ('停车月卡', 'MdiIcons.car'),
    ('健身房会员', 'MdiIcons.dumbbell'),
    ('运动场馆卡', 'MdiIcons.basketball'),
    ('外卖会员', 'MdiIcons.moped'),
    ('电商会员', 'MdiIcons.shopping'),
    ('生鲜买菜会员', 'MdiIcons.carrot'),
    ('山姆/Costco会员', 'MdiIcons.cartVariant'),
    ('咖啡月卡', 'MdiIcons.coffeeMaker'),
    ('手机套餐', 'MdiIcons.cellphone'),
    ('宽带/网络套餐', 'MdiIcons.routerWireless'),
    ('流量包/eSIM', 'MdiIcons.cellphone'),
    ('域名/云服务器', 'MdiIcons.cloudUpload'),
    ('GitHub Copilot', 'MdiIcons.robot'),
    ('Notion/知识库', 'MdiIcons.notebook'),
    ('网课/学习会员', 'MdiIcons.bookOpenPageVariant'),
    ('阅读会员', 'MdiIcons.book'),
    ('保险/保单', 'MdiIcons.shieldKey'),
    ('效率工具订阅', 'MdiIcons.briefcase')
),
system_parent AS (
  SELECT "id"
  FROM "Category"
  WHERE "userId" IS NULL
    AND "parentId" IS NULL
    AND "name" = '虚拟订阅'
  LIMIT 1
)
INSERT INTO "Category" (
  "id",
  "name",
  "icon",
  "userId",
  "parentId",
  "isVirtual",
  "createdAt",
  "updatedAt"
)
SELECT
  md5('subscription-template:' || parent."id" || ':' || template."name"),
  template."name",
  template."icon",
  NULL,
  parent."id",
  false,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM subscription_templates AS template
CROSS JOIN system_parent AS parent
WHERE NOT EXISTS (
  SELECT 1
  FROM "Category" AS existing
  WHERE existing."userId" IS NULL
    AND existing."parentId" = parent."id"
    AND existing."name" = template."name"
);

WITH subscription_templates(name, icon) AS (
  VALUES
    ('共享单车月卡', 'MdiIcons.bicycle'),
    ('公交/地铁月票', 'MdiIcons.cardBulleted'),
    ('停车月卡', 'MdiIcons.car'),
    ('健身房会员', 'MdiIcons.dumbbell'),
    ('运动场馆卡', 'MdiIcons.basketball'),
    ('外卖会员', 'MdiIcons.moped'),
    ('电商会员', 'MdiIcons.shopping'),
    ('生鲜买菜会员', 'MdiIcons.carrot'),
    ('山姆/Costco会员', 'MdiIcons.cartVariant'),
    ('咖啡月卡', 'MdiIcons.coffeeMaker'),
    ('手机套餐', 'MdiIcons.cellphone'),
    ('宽带/网络套餐', 'MdiIcons.routerWireless'),
    ('流量包/eSIM', 'MdiIcons.cellphone'),
    ('域名/云服务器', 'MdiIcons.cloudUpload'),
    ('GitHub Copilot', 'MdiIcons.robot'),
    ('Notion/知识库', 'MdiIcons.notebook'),
    ('网课/学习会员', 'MdiIcons.bookOpenPageVariant'),
    ('阅读会员', 'MdiIcons.book'),
    ('保险/保单', 'MdiIcons.shieldKey'),
    ('效率工具订阅', 'MdiIcons.briefcase')
),
user_parents AS (
  SELECT "id", "userId"
  FROM "Category"
  WHERE "userId" IS NOT NULL
    AND "parentId" IS NULL
    AND "name" = '虚拟订阅'
)
INSERT INTO "Category" (
  "id",
  "name",
  "icon",
  "userId",
  "parentId",
  "isVirtual",
  "createdAt",
  "updatedAt"
)
SELECT
  md5('subscription-template:' || parent."id" || ':' || template."name"),
  template."name",
  template."icon",
  parent."userId",
  parent."id",
  false,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
FROM subscription_templates AS template
CROSS JOIN user_parents AS parent
WHERE NOT EXISTS (
  SELECT 1
  FROM "Category" AS existing
  WHERE existing."userId" = parent."userId"
    AND existing."parentId" = parent."id"
    AND existing."name" = template."name"
);
