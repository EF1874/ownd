import { Prisma } from '@prisma/client';

export type ItemStatusFilter =
  | 'active'
  | 'inactive'
  | 'expired-subscriptions'
  | 'scrapped-items'
  | 'expiring-soon';

export function itemStatusFilter(
  status?: string,
): ItemStatusFilter | undefined {
  switch (status) {
    case 'active':
    case 'inactive':
    case 'expired-subscriptions':
    case 'scrapped-items':
    case 'expiring-soon':
      return status;
    default:
      return undefined;
  }
}

export function itemStatusWhereSql(
  status: ItemStatusFilter,
  today: Date,
  sevenDaysLater: Date,
): Prisma.Sql {
  switch (status) {
    case 'active':
      return Prisma.sql`NOT ${inactiveItemWhereSql(today)}`;
    case 'inactive':
      return inactiveItemWhereSql(today);
    case 'expired-subscriptions':
      return expiredSubscriptionWhereSql(today);
    case 'scrapped-items':
      return scrappedItemWhereSql();
    case 'expiring-soon':
      return expiringSoonItemWhereSql(today, sevenDaysLater);
  }
}

export function inactiveItemWhereSql(today: Date): Prisma.Sql {
  return Prisma.sql`(${scrappedItemWhereSql()} OR ${expiredSubscriptionWhereSql(today)})`;
}

function scrappedItemWhereSql(): Prisma.Sql {
  return Prisma.sql`(i."isScrapped" = true AND i."scrappedDate" IS NOT NULL)`;
}

function expiredSubscriptionWhereSql(today: Date): Prisma.Sql {
  return Prisma.sql`(
    i."isVirtual" = true
    AND i."isAutoRenew" = false
    AND i."nextBillingDate" < ${today}
  )`;
}

function expiringSoonItemWhereSql(
  today: Date,
  sevenDaysLater: Date,
): Prisma.Sql {
  return Prisma.sql`(
    i."isVirtual" = true
    AND i."nextBillingDate" >= ${today}
    AND i."nextBillingDate" <= ${sevenDaysLater}
  )`;
}
