import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/purchase_platform.dart';
import '../../../data/repositories/platform_repository.dart';
import '../../../core/network/error_messages.dart';
import '../../../shared/utils/icon_utils.dart';

class HomeSliverAppBar extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isGridView;
  final String? statusFilter;
  final String sortField;
  final bool isAscending;
  final String? selectedPlatformFilter;

  final ValueChanged<bool> onGridViewChanged;
  final ValueChanged<String?> onStatusFilterChanged;
  final ValueChanged<String> onSortFieldChanged;
  final ValueChanged<bool> onSortOrderChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final VoidCallback onSearchChanged;
  final VoidCallback onAddDevice;

  const HomeSliverAppBar({
    super.key,
    required this.searchController,
    required this.isGridView,
    required this.statusFilter,
    required this.sortField,
    required this.isAscending,
    required this.selectedPlatformFilter,
    required this.onGridViewChanged,
    required this.onStatusFilterChanged,
    required this.onSortFieldChanged,
    required this.onSortOrderChanged,
    required this.onPlatformFilterChanged,
    required this.onSearchChanged,
    required this.onAddDevice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const buttonSize = 40.0;

    return SliverAppBar(
      floating: false, // Changed to false to keep it persistent
      pinned: true,
      toolbarHeight: 64,
      titleSpacing: 16,
      backgroundColor: theme.scaffoldBackgroundColor, // Ensure opaque
      surfaceTintColor: theme.scaffoldBackgroundColor,
      expandedHeight: 64,
      title: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: SizedBox(
                  height: buttonSize,
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => onSearchChanged(),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: '搜索物品',
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: buttonSize,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            constraints: const BoxConstraints.tightFor(
              width: buttonSize,
              height: buttonSize,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: isGridView ? '列表视图' : '网格视图',
            onPressed: () => onGridViewChanged(!isGridView),
          ),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                statusFilter != null || selectedPlatformFilter != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
              tooltip: '筛选',
              itemBuilder: (context) {
                const double itemHeight = 36.0;
                final textStyle = Theme.of(context).textTheme.bodyMedium;
                return [
                  _statusMenuItem(context, null, itemHeight, textStyle),
                  _statusMenuItem(context, 'active', itemHeight, textStyle),
                  _statusMenuItem(context, 'inactive', itemHeight, textStyle),
                  _statusMenuItem(
                    context,
                    'expired-subscriptions',
                    itemHeight,
                    textStyle,
                  ),
                  _statusMenuItem(
                    context,
                    'scrapped-items',
                    itemHeight,
                    textStyle,
                  ),
                  _statusMenuItem(
                    context,
                    'expiring-soon',
                    itemHeight,
                    textStyle,
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'platform_filter',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 18,
                          color: selectedPlatformFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedPlatformFilter == null
                              ? '平台筛选'
                              : '平台: $selectedPlatformFilter',
                          style: textStyle,
                        ),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (v) {
                if (v.startsWith('status_')) {
                  final rawValue = v.substring(7);
                  final value = rawValue == 'all' ? null : rawValue;
                  onStatusFilterChanged(statusFilter == value ? null : value);
                } else if (v == 'platform_filter') {
                  _showPlatformFilterDialog(context);
                }
              },
            ),
          ),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.sort),
              tooltip: '排序',
              itemBuilder: (context) {
                const double itemHeight = 36.0;
                final textStyle = Theme.of(context).textTheme.bodyMedium;
                return [
                  PopupMenuItem(
                    value: 'field_default',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_motion_outlined,
                          size: 18,
                          color: sortField == 'default'
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('默认排序', style: textStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'field_date',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: sortField == 'date'
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('购买日期', style: textStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'field_price',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 18,
                          color: sortField == 'price'
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('价格', style: textStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'field_expiry',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: sortField == 'expiry'
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('到期/报废时间', style: textStyle),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'order_desc',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 18,
                          color: !isAscending
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('倒序', style: textStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'order_asc',
                    height: itemHeight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: isAscending
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('顺序', style: textStyle),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (v) {
                if (v.startsWith('field_')) {
                  onSortFieldChanged(v.substring(6));
                } else if (v == 'order_asc') {
                  onSortOrderChanged(true);
                } else if (v == 'order_desc') {
                  onSortOrderChanged(false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _statusMenuItem(
    BuildContext context,
    String? value,
    double itemHeight,
    TextStyle? textStyle,
  ) {
    final selected = statusFilter == value;
    return PopupMenuItem(
      value: 'status_${value ?? 'all'}',
      height: itemHeight,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : _statusIcon(value),
            size: 18,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Text(_statusLabel(value), style: textStyle),
        ],
      ),
    );
  }

  IconData _statusIcon(String? value) {
    return switch (value) {
      'active' => Icons.play_circle_outline,
      'inactive' => Icons.archive_outlined,
      'expired-subscriptions' => Icons.event_busy_outlined,
      'scrapped-items' => Icons.delete_sweep_outlined,
      'expiring-soon' => Icons.notifications_active_outlined,
      _ => Icons.all_inbox_outlined,
    };
  }

  String _statusLabel(String? value) {
    return switch (value) {
      'active' => '使用中',
      'inactive' => '退役/到期',
      'expired-subscriptions' => '已过期订阅',
      'scrapped-items' => '已报废实物',
      'expiring-soon' => '即将到期订阅',
      _ => '全部物品',
    };
  }

  void _showPlatformFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Consumer(
            builder: (context, ref, child) {
              final platformsAsync = ref.watch(platformsProvider);

              return Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      child: Text(
                        '选择平台',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: platformsAsync.when(
                        data: (platforms) => ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              dense: true,
                              title: const Text('全部平台'),
                              leading: selectedPlatformFilter == null
                                  ? Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    )
                                  : const SizedBox(width: 20),
                              onTap: () {
                                onPlatformFilterChanged(null);
                                Navigator.pop(context);
                              },
                            ),
                            ...platforms.map((p) {
                              final isSelected =
                                  selectedPlatformFilter == p.name;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  IconUtils.getIconData(p.iconPath),
                                  size: 20,
                                  color: _platformColor(p),
                                ),
                                title: Text(p.name),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    : null,
                                onTap: () {
                                  onPlatformFilterChanged(
                                    isSelected ? null : p.name,
                                  );
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text('加载失败: ${userErrorMessage(err)}'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _platformColor(PurchasePlatform platform) {
    final normalized = platform.colorHex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return Colors.grey;

    return Color(0xFF000000 | value);
  }
}
