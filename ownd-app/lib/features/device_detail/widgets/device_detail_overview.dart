part of '../device_detail_screen.dart';

extension _DeviceDetailOverview on DeviceDetailScreen {
  Widget _buildHeaderBackground(
    Device device,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (device.imagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => ImagePreviewDialog.show(context, device.imagePath!),
            child: Hero(
              tag: 'device_image_${device.id}',
              child: AppImage(path: device.imagePath!),
            ),
          ),
        ],
      );
    }

    final color =
        CategoryUtils.getCategoryColor(device.category.value?.name) ??
        theme.colorScheme.primary;
    final item = CategoryConfig.getItem(device.category.value?.name);
    final iconData = IconUtils.getIconData(item.iconPath);

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
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
        ),
      ],
    );
  }

  Future<void> _changeHeaderImage(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickAndCropImage(
      context: context,
      source: ImageSource.gallery,
      isSquare: false,
    );
    if (file == null || !context.mounted) return;

    final savedPath = await imageService.saveImageToAppDirectory(
      file,
      device.uuid,
      isIcon: false,
    );
    if (savedPath == null) {
      if (context.mounted) {
        AppToast.show(context, '图片保存失败，请重试', isError: true);
      }
      return;
    }
    if (!context.mounted) return;

    final oldImagePath = device.imagePath;
    try {
      device.imagePath = savedPath;
      await ref.read(deviceRepositoryProvider).updateDevice(device);
      if (!context.mounted) return;
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (context.mounted) AppToast.show(context, '图片已更新');
    } catch (e) {
      device.imagePath = oldImagePath;
      if (!context.mounted) return;
      AppToast.show(context, '图片更新失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _deleteHeaderImage(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final oldImagePath = device.imagePath;
    try {
      device.imagePath = null;
      await ref.read(deviceRepositoryProvider).updateDevice(device);
      if (!context.mounted) return;
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (context.mounted) AppToast.show(context, '图片已删除');
    } catch (e) {
      device.imagePath = oldImagePath;
      if (!context.mounted) return;
      AppToast.show(context, '图片删除失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Widget _buildCostAnalysisCard(Device device, ThemeData theme) {
    final dailyCostStr = FormatUtils.formatCurrency(device.dailyCost);
    final isSub = CategoryTreeUtils.isVirtualSubscription(
      device.category.value,
    );
    final totalCostStr = FormatUtils.formatCurrency(
      isSub ? _subscriptionTotal(device) : device.totalAccumulatedPrice,
    );
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
                prefix: '¥',
                number: FormatUtils.formatCurrency(device.price),
                valueColor: theme.colorScheme.primary,
              ),
              _CostMetric(
                label: isSub ? '累计支出' : '日均成本',
                prefix: '¥',
                number: isSub ? totalCostStr : dailyCostStr,
                valueColor: costColor ?? theme.colorScheme.error,
              ),
            ],
          ),
          if (!isSub) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InlineNumberText(
                  prefix: '已使用 ',
                  number: '${device.daysUsed}',
                  suffix: ' 天',
                  color: AppColors.ash,
                  numberStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _InlineNumberText(
                  prefix: '月均 ¥',
                  number: FormatUtils.formatCurrency(device.dailyCost * 30),
                  color: AppColors.ash,
                  numberStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
          if ((device.platform ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _InfoRow(label: '平台/渠道', value: device.platform!),
          ],
          if (device.warrantyEndDate != null) ...[
            const Divider(height: 24),
            _InfoRow(
              label: '保修截止',
              value: dateFormat.format(device.warrantyEndDate!),
            ),
          ],
        ],
      ),
    );
  }

  double _subscriptionTotal(Device device) {
    if (device.history.isEmpty) return device.totalAccumulatedPrice;
    return device.history.fold<double>(
      0,
      (total, history) => total + history.price,
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
}
