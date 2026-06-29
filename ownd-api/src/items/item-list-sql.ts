import { Prisma } from '@prisma/client';
import dayjs from 'dayjs';
import { PrismaService } from '../prisma/prisma.service';
import type { FindItemsQuery } from './item-list-query';
import { itemOrderSql } from './item-list-order-sql';
import { itemStatusFilter, itemStatusWhereSql } from './item-list-status-sql';

type OrderedItemRow = { id: string };

export async function findOrderedItemIds(
  prisma: PrismaService,
  userId: string,
  query: FindItemsQuery | undefined,
) {
  const rows = await prisma.$queryRaw<OrderedItemRow[]>(
    orderedItemIdsQuery(userId, query),
  );
  return rows.map((row) => row.id);
}

function orderedItemIdsQuery(
  userId: string,
  query?: FindItemsQuery,
): Prisma.Sql {
  const today = dayjs().startOf('day').toDate();
  const sevenDaysLater = dayjs().add(7, 'day').endOf('day').toDate();

  return Prisma.sql`
    SELECT i."id"
    FROM "Item" i
    LEFT JOIN LATERAL (
      SELECT ih."startDate"
      FROM "ItemHistory" ih
      WHERE ih."itemId" = i."id"
      ORDER BY ih."startDate" DESC NULLS LAST
      LIMIT 1
    ) latest_start ON true
    ${itemWhereSql(userId, query, today, sevenDaysLater)}
    ${itemOrderSql(query, today)}
    ${paginationSql(query)}
  `;
}

function itemWhereSql(
  userId: string,
  query: FindItemsQuery | undefined,
  today: Date,
  sevenDaysLater: Date,
): Prisma.Sql {
  const conditions: Prisma.Sql[] = [Prisma.sql`i."userId" = ${userId}`];
  const search = query?.search?.trim();

  if (search) {
    const pattern = `%${search}%`;
    conditions.push(Prisma.sql`(
      i."name" ILIKE ${pattern}
      OR i."notes" ILIKE ${pattern}
      OR i."tags" @> ARRAY[${search}]::text[]
      OR EXISTS (
        SELECT 1 FROM "Platform" p
        WHERE p."id" = i."platformId" AND p."name" ILIKE ${pattern}
      )
      OR EXISTS (
        SELECT 1
        FROM "Category" c
        LEFT JOIN "Category" pc ON pc."id" = c."parentId"
        WHERE c."id" = i."categoryId"
          AND (c."name" ILIKE ${pattern} OR pc."name" ILIKE ${pattern})
      )
      OR EXISTS (
        SELECT 1 FROM "ItemHistory" ih
        WHERE ih."itemId" = i."id" AND ih."note" ILIKE ${pattern}
      )
    )`);
  }

  if (query?.categoryId) {
    const categoryIds = query.categoryId.split(',').filter(Boolean);
    if (categoryIds.length > 0) {
      conditions.push(Prisma.sql`(
        i."categoryId" IN (${Prisma.join(categoryIds)})
        OR EXISTS (
          SELECT 1 FROM "Category" c
          WHERE c."id" = i."categoryId"
            AND c."parentId" IN (${Prisma.join(categoryIds)})
        )
      )`);
    }
  }

  if (query?.platformId) {
    conditions.push(Prisma.sql`i."platformId" = ${query.platformId}`);
  }

  if (query?.tag) {
    const tags = query.tag
      .split(',')
      .map((tag) => tag.trim())
      .filter(Boolean);
    if (tags.length > 0) {
      conditions.push(
        Prisma.sql`i."tags" @> ARRAY[${Prisma.join(tags)}]::text[]`,
      );
    }
  }

  const statusFilter = itemStatusFilter(query?.status);
  if (query?.expiringSoon && statusFilter === undefined) {
    conditions.push(itemStatusWhereSql('expiring-soon', today, sevenDaysLater));
  } else if (statusFilter !== undefined) {
    conditions.push(itemStatusWhereSql(statusFilter, today, sevenDaysLater));
  }

  return Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}`;
}

function paginationSql(query?: FindItemsQuery): Prisma.Sql {
  if (!query?.page || !query?.limit) return Prisma.sql``;

  const take = Math.max(Number(query.limit), 1);
  const skip = (Math.max(Number(query.page), 1) - 1) * take;
  return Prisma.sql`LIMIT ${take} OFFSET ${skip}`;
}
