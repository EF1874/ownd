import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/purchase_platform.dart';
import '../../../data/repositories/platform_repository.dart';
import '../../../core/network/error_messages.dart';
import '../../../shared/utils/icon_utils.dart';

class PlatformPicker extends ConsumerWidget {
  final String? selectedPlatform;
  final ValueChanged<String> onPlatformSelected;

  const PlatformPicker({
    super.key,
    this.selectedPlatform,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformsAsync = ref.watch(platformsProvider);
    final selectedModel = platformsAsync.valueOrNull?.firstWhere(
      (p) => p.name == selectedPlatform,
      orElse: () => PurchasePlatform(
        id: -1,
        uuid: '',
        name: selectedPlatform ?? '',
        iconPath: 'MdiIcons.store',
        colorHex: '#9E9E9E',
        isDefault: false,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPlatformSheet(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '购买平台',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
              errorStyle: TextStyle(height: 0),
            ),
            child: selectedPlatform != null && selectedPlatform!.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconUtils.getIconData(
                          selectedModel?.iconPath ?? 'MdiIcons.store',
                        ),
                        size: 20,
                        color: _platformColor(selectedModel),
                      ),
                      const SizedBox(width: 8),
                      Text(selectedPlatform!),
                    ],
                  )
                : const Text('请选择平台', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _showPlatformSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final sheetPlatformsAsync = ref.watch(platformsProvider);

          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: 500,
            child: Column(
              children: [
                Text('选择购买平台', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: sheetPlatformsAsync.when(
                    data: (platforms) => SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: platforms.map((platform) {
                          final isSelected = selectedPlatform == platform.name;
                          return ChoiceChip(
                            label: Text(platform.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                onPlatformSelected(platform.name);
                                Navigator.pop(ctx);
                              }
                            },
                            avatar: Icon(
                              IconUtils.getIconData(platform.iconPath),
                              size: 18,
                              color: _platformColor(platform),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('加载失败: ${userErrorMessage(err)}')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _platformColor(PurchasePlatform? platform) {
    final colorHex = platform?.colorHex;
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;

    final normalized = colorHex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return Colors.grey;

    return Color(0xFF000000 | value);
  }
}
