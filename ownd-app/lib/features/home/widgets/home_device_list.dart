import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../shared/config/category_config.dart';
import 'summary_card.dart';
import 'device_list_item.dart';
import 'device_grid_item.dart';

class HomeDeviceList extends StatelessWidget {
  final List<Device> processedDevices;
  final List<Device> allDevices;
  final bool showExpiringList;
  final bool isGridView;
  final String? categoryName;
  final OnDeleteComplete? onDeleteComplete;

  const HomeDeviceList({
    super.key,
    required this.processedDevices,
    required this.allDevices,
    required this.showExpiringList,
    required this.isGridView,
    this.categoryName,
    this.onDeleteComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Split logic
    List<Device> expiring = [];
    List<Device> normal = [];

    if (showExpiringList) {
      final now = DateTime.now();
      for (var d in processedDevices) {
        bool isExpiring = false;
        // Check Sub + Reminder Logic
        if (CategoryConfig.getMajorCategory(d.category.value?.name) == '虚拟订阅') {
          if (d.nextBillingDate != null) {
            int diff = d.nextBillingDate!.difference(now).inDays;

            if (d.hasReminder && diff <= d.reminderDays && diff >= 0) {
              isExpiring = true;
            }
          }
        }

        if (isExpiring) {
          expiring.add(d);
        } else {
          normal.add(d);
        }
      }
    } else {
      normal = processedDevices;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Summary Card (Placed here to use processed data)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SummaryCard(
                filteredDevices: processedDevices,
                allDevices: allDevices,
                categoryName: categoryName,
              ),
            ),
          ),
          // Expiring Section
          if (expiring.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                child: Text(
                  '即将到期 / 续费',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            isGridView
                ? SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DeviceGridItem(device: expiring[index], index: index, key: ValueKey(expiring[index].id), onDeleteComplete: onDeleteComplete),
                      childCount: expiring.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DeviceListItem(device: expiring[index], index: index, key: ValueKey(expiring[index].id), onDeleteComplete: onDeleteComplete),
                      childCount: expiring.length,
                    ),
                  ),
            SliverToBoxAdapter(
              child: Divider(
                height: 32,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ],

          // Normal Section
          if (normal.isNotEmpty) ...[
            isGridView
                ? SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DeviceGridItem(
                        device: normal[index],
                        index: index + expiring.length,
                        key: ValueKey(normal[index].id),
                        onDeleteComplete: onDeleteComplete,
                      ),
                      childCount: normal.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DeviceListItem(
                        device: normal[index],
                        index: index + expiring.length,
                        key: ValueKey(normal[index].id),
                        onDeleteComplete: onDeleteComplete,
                      ),
                      childCount: normal.length,
                    ),
                  ),
          ],

          if (normal.isEmpty && expiring.isNotEmpty)
            // Show nothing extra
            const SliverToBoxAdapter(child: SizedBox.shrink()),

          if (processedDevices.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child:
                    Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无数据',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '当前分类下没有相关物品',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 32), // Visual balance
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                          begin: 0.1,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
