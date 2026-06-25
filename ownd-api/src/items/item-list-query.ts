import { Prisma } from '@prisma/client';
import dayjs from 'dayjs';
import * as cacheManager from 'cache-manager';
import { PrismaService } from '../prisma/prisma.service';

export type FindItemsQuery = {
  search?: string;
  page?: number;
  limit?: number;
  categoryId?: string;
  platformId?: string;
  tag?: string;
  expiringSoon?: boolean;
  status?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
};

export const itemListInclude = {
  category: { include: { parent: true } },
  platform: true,
  itemHistories: {
    orderBy: { startDate: 'desc' },
    take: 1,
  },
} satisfies Prisma.ItemInclude;

export type ItemWithRelations = Prisma.ItemGetPayload<{
  include: typeof itemListInclude;
}>;

type ItemStatusFilter =
  | 'active'
  | 'inactive'
  | 'expired-subscriptions'
  | 'scrapped-items'
  | 'expiring-soon';

type ListItemsDeps = {
  prisma: PrismaService;
  cacheManager: cacheManager.Cache;
};

export async function listItems(
  { prisma, cacheManager }: ListItemsDeps,
  userId: string,
  query?: FindItemsQuery,
) {
  const isFiltered = query
    ? Object.values(query).some(
        (value) => value !== undefined && value !== false,
      )
    : false;
  const cacheKey = `user:${userId}:items`;

  if (!isFiltered) {
    try {
      const cached = await cacheManager.get<ItemWithRelations[]>(cacheKey);
      if (cached) return cached;
    } catch {
      // ignore
    }
  }

  const where = buildItemWhere(query, userId);
  const statusFilter = itemStatusFilter(query?.status);
  const today = dayjs().startOf('day').toDate();
  const inactiveWhere = inactiveItemWhere(today);
  const { skip, take } = pagination(query);

  // ponytail: personal inventories are small; use raw SQL if this list grows large.
  const fetchItems = (whereInput: Prisma.ItemWhereInput) =>
    prisma.item.findMany({
      where: whereInput,
      include: itemListInclude,
    });

  let items: ItemWithRelations[];
  if (statusFilter === undefined && !query?.expiringSoon) {
    const baseAndConditions = normalizedAndConditions(where);
    const activeWhere: Prisma.ItemWhereInput = {
      ...where,
      AND: [...baseAndConditions, { NOT: inactiveWhere }],
    };
    const retiredWhere: Prisma.ItemWhereInput = {
      ...where,
      AND: [...baseAndConditions, inactiveWhere],
    };
    const activeItems = sortItems(await fetchItems(activeWhere), query);
    const retiredItems = sortItems(await fetchItems(retiredWhere), query);
    items = [...activeItems, ...retiredItems];
  } else {
    items = sortItems(await fetchItems(where), query);
  }

  const pagedItems =
    skip !== undefined && take !== undefined
      ? items.slice(skip, skip + take)
      : items;

  if (!isFiltered) {
    try {
      await cacheManager.set(cacheKey, pagedItems, 600000);
    } catch {
      // ignore
    }
  }

  return pagedItems;
}

function buildItemWhere(
  query: FindItemsQuery | undefined,
  userId: string,
): Prisma.ItemWhereInput {
  const where: Prisma.ItemWhereInput = { userId };
  const andConditions: Prisma.ItemWhereInput[] = [];

  const search = query?.search?.trim();
  if (search) andConditions.push(searchWhere(search));

  if (query?.categoryId) {
    const categoryIds = query.categoryId.split(',');
    andConditions.push({
      OR: [
        { categoryId: { in: categoryIds } },
        { category: { parentId: { in: categoryIds } } },
      ],
    });
  }

  if (query?.platformId) andConditions.push({ platformId: query.platformId });

  if (query?.tag) {
    const tags = query.tag.split(',');
    andConditions.push({ tags: { hasEvery: tags } });
  }

  const statusFilter = itemStatusFilter(query?.status);
  const today = dayjs().startOf('day').toDate();
  const sevenDaysLater = dayjs().add(7, 'day').endOf('day').toDate();

  if (query?.expiringSoon && statusFilter === undefined) {
    andConditions.push(expiringSoonItemWhere(today, sevenDaysLater));
  } else if (statusFilter !== undefined) {
    andConditions.push(itemStatusWhere(statusFilter, today, sevenDaysLater));
  }

  if (andConditions.length > 0) where.AND = andConditions;
  return where;
}

function searchWhere(search: string): Prisma.ItemWhereInput {
  return {
    OR: [
      { name: { contains: search, mode: Prisma.QueryMode.insensitive } },
      { notes: { contains: search, mode: Prisma.QueryMode.insensitive } },
      { tags: { has: search } },
      {
        platform: {
          is: {
            name: { contains: search, mode: Prisma.QueryMode.insensitive },
          },
        },
      },
      {
        category: {
          is: {
            OR: [
              {
                name: {
                  contains: search,
                  mode: Prisma.QueryMode.insensitive,
                },
              },
              {
                parent: {
                  is: {
                    name: {
                      contains: search,
                      mode: Prisma.QueryMode.insensitive,
                    },
                  },
                },
              },
            ],
          },
        },
      },
      {
        itemHistories: {
          some: {
            note: { contains: search, mode: Prisma.QueryMode.insensitive },
          },
        },
      },
    ],
  };
}

function itemStatusFilter(status?: string): ItemStatusFilter | undefined {
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

function itemStatusWhere(
  status: ItemStatusFilter,
  today: Date,
  sevenDaysLater: Date,
): Prisma.ItemWhereInput {
  switch (status) {
    case 'active':
      return { NOT: inactiveItemWhere(today) };
    case 'inactive':
      return inactiveItemWhere(today);
    case 'expired-subscriptions':
      return expiredSubscriptionWhere(today);
    case 'scrapped-items':
      return scrappedItemWhere();
    case 'expiring-soon':
      return expiringSoonItemWhere(today, sevenDaysLater);
  }
}

function inactiveItemWhere(today: Date): Prisma.ItemWhereInput {
  return { OR: [scrappedItemWhere(), expiredSubscriptionWhere(today)] };
}

function scrappedItemWhere(): Prisma.ItemWhereInput {
  return { isScrapped: true, scrappedDate: { not: null } };
}

function expiredSubscriptionWhere(today: Date): Prisma.ItemWhereInput {
  return {
    isVirtual: true,
    isAutoRenew: false,
    nextBillingDate: { lt: today },
  };
}

function expiringSoonItemWhere(
  today: Date,
  sevenDaysLater: Date,
): Prisma.ItemWhereInput {
  return {
    isVirtual: true,
    nextBillingDate: { gte: today, lte: sevenDaysLater },
  };
}

function pagination(query?: FindItemsQuery) {
  if (!query?.page || !query?.limit) return {};
  const page = Number(query.page);
  const limit = Number(query.limit);
  return { skip: (page - 1) * limit, take: limit };
}

function normalizedAndConditions(where: Prisma.ItemWhereInput) {
  if (where.AND === undefined) return [];
  return Array.isArray(where.AND) ? where.AND : [where.AND];
}

function sortItems(items: ItemWithRelations[], query?: FindItemsQuery) {
  return [...items].sort(itemComparator(query));
}

function itemComparator(query?: FindItemsQuery) {
  const sortBy = query?.sortBy;
  const order = query?.sortOrder === 'asc' ? 1 : -1;
  return (a: ItemWithRelations, b: ItemWithRelations) => {
    const result =
      sortBy === 'price'
        ? compareNumbers(a.price, b.price) * order
        : sortBy === 'date'
          ? compareNullableDates(
              manualPurchaseDate(a),
              manualPurchaseDate(b),
              order,
            )
          : sortBy === 'expiry'
            ? compareNullableDates(expiryDate(a), expiryDate(b), order)
            : compareNumbers(defaultSortRank(a), defaultSortRank(b));

    return result || a.name.localeCompare(b.name) || a.id.localeCompare(b.id);
  };
}

function manualPurchaseDate(item: ItemWithRelations) {
  if (!item.isVirtual) return item.purchaseDate;
  return item.itemHistories[0]?.startDate ?? item.purchaseDate;
}

function expiryDate(item: ItemWithRelations) {
  return item.isVirtual ? item.nextBillingDate : item.scrappedDate;
}

function defaultSortRank(item: ItemWithRelations) {
  const today = dayjs().startOf('day');
  if (item.isVirtual) {
    const dueDate = item.nextBillingDate ? dayjs(item.nextBillingDate) : null;
    return dueDate ? dueDate.diff(today, 'day') : Number.MAX_SAFE_INTEGER;
  }
  return today.diff(dayjs(item.purchaseDate), 'day');
}

function compareNullableDates(
  a: Date | null | undefined,
  b: Date | null | undefined,
  order: 1 | -1,
) {
  if (!a && !b) return 0;
  if (!a) return 1;
  if (!b) return -1;
  return compareNumbers(a.getTime(), b.getTime()) * order;
}

function compareNumbers(a: number, b: number) {
  return a === b ? 0 : a < b ? -1 : 1;
}
