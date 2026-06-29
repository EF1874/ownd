import { Prisma } from '@prisma/client';
import * as cacheManager from 'cache-manager';
import { PrismaService } from '../prisma/prisma.service';
import { findOrderedItemIds } from './item-list-sql';

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

type ListItemsDeps = {
  prisma: PrismaService;
  cacheManager: cacheManager.Cache;
};

export async function listItems(
  { prisma, cacheManager }: ListItemsDeps,
  userId: string,
  query?: FindItemsQuery,
) {
  const cacheKey = `user:${userId}:items`;

  if (canUseListCache(query)) {
    try {
      const cached = await cacheManager.get<ItemWithRelations[]>(cacheKey);
      if (cached) return cached;
    } catch {
      // ignore
    }
  }

  const orderedIds = await findOrderedItemIds(prisma, userId, query);
  if (orderedIds.length === 0) return [];

  const pageItems = await prisma.item.findMany({
    where: { id: { in: orderedIds } },
    include: itemListInclude,
  });
  const result = restoreSqlOrder(pageItems, orderedIds);

  if (canUseListCache(query)) {
    try {
      await cacheManager.set(cacheKey, result, 600000);
    } catch {
      // ignore
    }
  }

  return result;
}

function canUseListCache(query?: FindItemsQuery) {
  return query
    ? Object.values(query).every(
        (value) => value === undefined || value === false,
      )
    : true;
}

function restoreSqlOrder(
  items: ItemWithRelations[],
  orderedIds: string[],
): ItemWithRelations[] {
  const order = new Map(orderedIds.map((id, index) => [id, index]));
  return [...items].sort(
    (a, b) =>
      (order.get(a.id) ?? Number.MAX_SAFE_INTEGER) -
      (order.get(b.id) ?? Number.MAX_SAFE_INTEGER),
  );
}
