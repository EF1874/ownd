import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/category_utils.dart';
import '../../shared/utils/icon_utils.dart';
import '../../shared/utils/format_utils.dart';
import '../../shared/config/cost_config.dart';
import '../../shared/widgets/base_card.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart'; // for deviceListProvider
import '../add_device/add_device_screen.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final int id;
  const DeviceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevices = ref.watch(deviceListProvider);
    final theme = Theme.of(context);

    return asyncDevices.when(
      data: (devices) {
        final idx = devices.indexWhere((d) => d.id == id);
        if (idx == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('错误')),
            body: const Center(child: Text('无法找到该物品')),
          );
        }
        final device = devices[idx];
        final isSub =
            CategoryConfig.getMajorCategory(device.category.value?.name) ==
            '虚拟订阅';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeaderBackground(device, theme),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                      // Status bar safety gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                            stops: [0.0, 0.4],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddDeviceScreen(device: device),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Header
                      Text(
                        device.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTagsSection(device, theme),
                      const SizedBox(height: 16),
                      _buildCostAnalysisCard(device, theme),
                      const SizedBox(height: 16),
                      _buildBasicInfoCard(device, theme),
                      const SizedBox(height: 16),
                      if (isSub) _buildSubscriptionHistory(device, theme),
                      if (device.notes != null && device.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesSection(device.notes!, theme),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('错误: $e'))),
    );
  }

  Widget _buildHeaderBackground(Device device, ThemeData theme) {
    if (device.imagePath != null) {
      return Hero(
        tag: 'device_image_${device.id}',
        child: Image.file(File(device.imagePath!), fit: BoxFit.cover),
      );
    }

    final color =
        CategoryUtils.getCategoryColor(device.category.value?.name) ??
        theme.colorScheme.primary;
    final item = CategoryConfig.getItem(device.category.value?.name);
    final iconData = IconUtils.getIconData(item.iconPath);

    return Hero(
      tag: 'device_icon_${device.id}',
      child: Container(
        color: color.withValues(alpha: 0.2),
        child: Center(
          child: device.customIconPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(device.customIconPath!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(iconData, size: 80, color: color),
        ),
      ),
    );
  }

  Widget _buildCostAnalysisCard(Device device, ThemeData theme) {
    final dailyCostStr = FormatUtils.formatCurrency(device.dailyCost);
    final isSub =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';
    final costColor = CostConfig.getCostColor(device.dailyCost);

    return BaseCard(
      variant: CardVariant.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '成本分析',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CostMetric(
                label: '购入价格',
                value: '¥${FormatUtils.formatCurrency(device.price)}',
                valueColor: theme.colorScheme.primary,
              ),
              _CostMetric(
                label: isSub ? '累计支出' : '日均成本',
                value: isSub
                    ? '¥${FormatUtils.formatCurrency(device.totalAccumulatedPrice)}'
                    : '¥$dailyCostStr',
                valueColor: costColor ?? theme.colorScheme.error,
              ),
            ],
          ),
          if (!isSub) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已使用 ${device.daysUsed} 天',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ash,
                  ),
                ),
                Text(
                  '月均 ¥${FormatUtils.formatCurrency(device.dailyCost * 30)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ash,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(Device device, ThemeData theme) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isSub =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';

    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '基础信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: '分类', value: device.category.value?.name ?? '未分类'),
          const Divider(height: 24),
          _InfoRow(
            label: '购入日期',
            value: dateFormat.format(device.purchaseDate),
          ),
          if (!isSub && (device.platform ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _InfoRow(label: '平台/渠道', value: device.platform!),
          ],
          if (!isSub && device.warrantyEndDate != null) ...[
            const Divider(height: 24),
            _InfoRow(
              label: '保修截止',
              value: dateFormat.format(device.warrantyEndDate!),
            ),
          ],
          if (isSub && device.nextBillingDate != null) ...[
            const Divider(height: 24),
            _InfoRow(
              label: '下次续费',
              value: dateFormat.format(device.nextBillingDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection(Device device, ThemeData theme) {
    if (device.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: device.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesSection(String notes, ThemeData theme) {
    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, color: AppColors.ash, size: 20),
              const SizedBox(width: 8),
              Text(
                '备注',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistory(Device device, ThemeData theme) {
    if (device.history.isEmpty) return const SizedBox.shrink();
    final dateFormat = DateFormat('yyyy-MM-dd');

    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.ash, size: 20),
              const SizedBox(width: 8),
              Text(
                '续费记录',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...device.history.reversed.map((h) {
            final start = h.startDate != null
                ? dateFormat.format(h.startDate!)
                : '?';
            final end = h.endDate != null ? dateFormat.format(h.endDate!) : '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$start 至 $end', style: theme.textTheme.bodySmall),
                  Text(
                    '¥${h.price}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CostMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _CostMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.ash),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.ash),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
