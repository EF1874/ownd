import 'package:flutter/material.dart';
import '../../../data/models/category.dart';
import '../../../shared/utils/category_tree_utils.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'category_picker.dart';
import 'platform_picker.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController customPlatformController;
  final TextEditingController customCategoryController;
  final Category? selectedCategory;
  final String? selectedPlatform;
  final Function(Category?) onCategorySelected;
  final Function(String?) onPlatformSelected;
  final String? customIconPath;
  final VoidCallback? onPickCustomIcon;
  final VoidCallback? onRemoveCustomIcon;

  const BasicInfoSection({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.customPlatformController,
    required this.customCategoryController,
    required this.selectedCategory,
    required this.selectedPlatform,
    required this.onCategorySelected,
    required this.onPlatformSelected,
    this.customIconPath,
    this.onPickCustomIcon,
    this.onRemoveCustomIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryPicker(
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
          customIconPath: customIconPath,
          onPickCustomIcon: onPickCustomIcon,
          onRemoveCustomIcon: onRemoveCustomIcon,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: nameController,
          builder: (context, value, child) {
            return AppTextField(
              controller: nameController,
              label: '名称 (选填)',
              hint: '默认使用分类名称',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => nameController.clear(),
                    )
                  : null,
            );
          },
        ),
        if (selectedCategory?.name == '其它') ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: customCategoryController,
            label: '请输入分类名称 (选填)',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
        if (!CategoryTreeUtils.isVirtualSubscription(selectedCategory)) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: priceController,
                  label: '价格',
                  labelStyle: TextStyle(color: Theme.of(context).hintColor),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PlatformPicker(
                  selectedPlatform: selectedPlatform,
                  onPlatformSelected: onPlatformSelected,
                ),
              ),
            ],
          ),
        ],
        if (selectedPlatform == '其它') ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: customPlatformController,
            label: '请输入平台名称',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
            validator: (v) => v?.isEmpty == true ? '请输入平台名称' : null,
          ),
        ],
      ],
    );
  }
}
