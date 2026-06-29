import { ItemCycleType } from '@prisma/client';
import { isVirtualBackupDevice } from './item-backup-import';

describe('isVirtualBackupDevice', () => {
  it('不应把 cycleType 为 null 的实体备份物品判断为虚拟订阅', () => {
    expect(
      isVirtualBackupDevice({
        isVirtual: false,
        cycleType: null,
        nextBillingDate: null,
        categoryName: '手机',
      }),
    ).toBe(false);
  });

  it('应该识别明确的虚拟订阅备份物品', () => {
    expect(
      isVirtualBackupDevice({
        isVirtual: true,
        cycleType: null,
        nextBillingDate: null,
        categoryName: '手机',
      }),
    ).toBe(true);
    expect(
      isVirtualBackupDevice({
        isVirtual: false,
        cycleType: ItemCycleType.MONTH,
        nextBillingDate: null,
        categoryName: '手机',
      }),
    ).toBe(true);
    expect(
      isVirtualBackupDevice({
        isVirtual: false,
        cycleType: null,
        nextBillingDate: new Date('2026-07-01T00:00:00.000Z'),
        categoryName: '手机',
      }),
    ).toBe(true);
  });
});
