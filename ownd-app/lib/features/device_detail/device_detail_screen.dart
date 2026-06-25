import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/services/preferences_service.dart';
import '../../core/network/error_messages.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/category_utils.dart';
import '../../shared/utils/icon_utils.dart';
import '../../shared/utils/format_utils.dart';
import '../../shared/utils/category_tree_utils.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/config/cost_config.dart';
import '../../shared/services/image_service.dart';
import '../../shared/services/subscription_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/image_preview_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_devices_provider.dart';
import '../add_device/add_device_screen.dart';
import 'widgets/renew_dialog.dart';

part 'widgets/device_detail_overview.dart';
part 'widgets/device_detail_subscription_info.dart';
part 'widgets/device_detail_subscription_history.dart';
part 'widgets/device_detail_components.dart';
part 'widgets/device_detail_common_widgets.dart';

final deviceDetailProvider = FutureProvider.autoDispose.family<Device, int>((
  ref,
  id,
) {
  return ref.read(deviceRepositoryProvider).getDevice(id);
});

class DeviceDetailScreen extends ConsumerWidget {
  final int id;
  const DeviceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevice = ref.watch(deviceDetailProvider(id));
    final theme = Theme.of(context);

    return asyncDevice.when(
      data: (device) {
        final isSub = CategoryTreeUtils.isVirtualSubscription(
          device.category.value,
        );

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
                      _buildHeaderBackground(device, theme, context, ref),
                      IgnorePointer(
                        child: Container(
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
                      ),
                      // Status bar safety gradient
                      IgnorePointer(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black54, Colors.transparent],
                              stops: [0.0, 0.4],
                            ),
                          ),
                        ),
                      ),
                      _HeaderImageButton(
                        icon: device.imagePath == null
                            ? Icons.add_a_photo_outlined
                            : Icons.camera_alt_outlined,
                        tooltip: device.imagePath == null ? '添加图片' : '更换图片',
                        onPressed: () =>
                            _changeHeaderImage(context, ref, device),
                      ),
                      if (device.imagePath != null)
                        _HeaderImageButton(
                          icon: Icons.delete_outline,
                          tooltip: '删除图片',
                          bottom: 80,
                          onPressed: () =>
                              _deleteHeaderImage(context, ref, device),
                        ),
                    ],
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: isSub
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddDeviceScreen(device: device),
                              ),
                            );
                            if (!context.mounted) return;
                            ref.invalidate(deviceDetailProvider(id));
                            await ref
                                .read(homeDevicesNotifierProvider.notifier)
                                .silentRefresh();
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
                      if (isSub) ...[
                        _buildSubscriptionInfoCard(device, theme, context, ref),
                        const SizedBox(height: 16),
                        _buildSubscriptionHistory(device, theme, context, ref),
                      ] else
                        _buildBasicInfoCard(device, theme),
                      if (!isSub &&
                          device.notes != null &&
                          device.notes!.isNotEmpty) ...[
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
      error: (e, s) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(userErrorMessage(e, fallback: '加载失败，请稍后重试')),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.invalidate(deviceDetailProvider(id)),
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
