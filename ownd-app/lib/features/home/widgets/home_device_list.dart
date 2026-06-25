import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import 'summary_card.dart';
import 'device_list_item.dart';
import 'device_grid_item.dart';

class HomeDeviceList extends StatelessWidget {
  final List<Device> processedDevices;
  final bool isGridView;
  final String emptyMessage;
  final OnDeleteComplete? onDeleteComplete;

  const HomeDeviceList({
    super.key,
    required this.processedDevices,
    required this.isGridView,
    required this.emptyMessage,
    this.onDeleteComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Summary Card (Placed here to use processed data)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: SummaryCard(),
            ),
          ),
          if (processedDevices.isNotEmpty) ...[
            isGridView
                ? SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => DeviceGridItem(
                        device: processedDevices[index],
                        index: index,
                        key: ValueKey(processedDevices[index].id),
                        onDeleteComplete: onDeleteComplete,
                      ),
                      childCount: processedDevices.length,
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
                        device: processedDevices[index],
                        index: index,
                        key: ValueKey(processedDevices[index].id),
                        onDeleteComplete: onDeleteComplete,
                      ),
                      childCount: processedDevices.length,
                    ),
                  ),
          ],

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
                              emptyMessage,
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
