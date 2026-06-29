import { Prisma } from '@prisma/client';
import type { FindItemsQuery } from './item-list-query';
import { inactiveItemWhereSql, itemStatusFilter } from './item-list-status-sql';

export function itemOrderSql(
  query: FindItemsQuery | undefined,
  today: Date,
): Prisma.Sql {
  const keepInactiveBottom =
    itemStatusFilter(query?.status) === undefined && !query?.expiringSoon;
  const inactivePrefix = keepInactiveBottom
    ? Prisma.sql`CASE WHEN ${inactiveItemWhereSql(today)} THEN 1 ELSE 0 END ASC,`
    : Prisma.sql``;

  if (query?.sortBy === 'price') {
    return Prisma.sql`ORDER BY
      ${inactivePrefix}
      i."price" ${sortDirectionSql(query)} NULLS LAST,
      i."name" ASC,
      i."id" ASC`;
  }

  if (query?.sortBy === 'date') {
    return Prisma.sql`ORDER BY
      ${inactivePrefix}
      COALESCE(latest_start."startDate", i."purchaseDate") ${sortDirectionSql(query)} NULLS LAST,
      i."name" ASC,
      i."id" ASC`;
  }

  if (query?.sortBy === 'expiry') {
    return Prisma.sql`ORDER BY
      ${inactivePrefix}
      CASE WHEN i."isVirtual" THEN i."nextBillingDate" ELSE i."scrappedDate" END
        ${sortDirectionSql(query)} NULLS LAST,
      i."name" ASC,
      i."id" ASC`;
  }

  const subscriptionCondition = subscriptionItemWhereSql();
  return Prisma.sql`ORDER BY
    CASE WHEN ${inactiveItemWhereSql(today)} THEN 1 ELSE 0 END ASC,
    CASE WHEN ${subscriptionCondition} THEN 0 ELSE 1 END ASC,
    CASE
      WHEN ${subscriptionCondition} THEN ABS(
        DATE_PART(
          'day',
          DATE_TRUNC('day', i."nextBillingDate")
            - DATE_TRUNC('day', ${today}::timestamp)
        )
      )
      ELSE NULL
    END ASC NULLS LAST,
    CASE WHEN NOT ${subscriptionCondition} THEN i."purchaseDate" ELSE NULL END DESC NULLS LAST,
    i."name" ASC,
    i."id" ASC`;
}

function sortDirectionSql(query: FindItemsQuery): Prisma.Sql {
  return query.sortOrder === 'asc' ? Prisma.sql`ASC` : Prisma.sql`DESC`;
}

function subscriptionItemWhereSql(): Prisma.Sql {
  return Prisma.sql`(i."isVirtual" = true AND i."nextBillingDate" IS NOT NULL)`;
}
