import 'package:flutter/material.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/image_preview_dialog.dart';

class AdditionalInfoSection extends StatelessWidget {
  final TextEditingController notesController;
  final TextEditingController tagsController;
  final String? imagePath;
  final bool showNotes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const AdditionalInfoSection({
    super.key,
    required this.notesController,
    required this.tagsController,
    this.imagePath,
    this.showNotes = true,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseCard(
      variant: CardVariant.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '更多信息 (选填)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: tagsController,
            label: '标签 (使用逗号分隔)',
            hint: '例如: 数码, 书籍, 生产力',
            labelStyle: TextStyle(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          if (showNotes) ...[
            AppTextField(
              controller: notesController,
              label: '备注',
              hint: '购买渠道、型号、感受等',
              maxLines: 3,
              labelStyle: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '物品相片',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: imagePath == null
                ? onPickImage
                : () => ImagePreviewDialog.show(context, imagePath!),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor,
                  style: BorderStyle.solid,
                ),
              ),
              child: imagePath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImage(path: imagePath!),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            tooltip: '删除图片',
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: onRemoveImage,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: IconButton(
                            tooltip: '更换图片',
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: onPickImage,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '添加照片',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
