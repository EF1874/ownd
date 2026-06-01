import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/widgets/image_preview_dialog.dart';

class CategoryPicker extends ConsumerWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onCategorySelected;
  final String? customIconPath;
  final VoidCallback? onPickCustomIcon;
  final VoidCallback? onRemoveCustomIcon;

  const CategoryPicker({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.customIconPath,
    this.onPickCustomIcon,
    this.onRemoveCustomIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? displayColor;
    if (selectedCategory != null) {
      // Direct lookup for Major Category color to ensure consistency
      if (CategoryConfig.majorCategoryColors.containsKey(
        selectedCategory!.name,
      )) {
        displayColor =
            CategoryConfig.majorCategoryColors[selectedCategory!.name];
      } else {
        displayColor = CategoryConfig.getItem(selectedCategory!.name).color;
      }
    }
    final selectedColor = displayColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showCategorySheet(context, ref),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '分类',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: selectedCategory != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconUtils.getIconData(selectedCategory!.iconPath),
                        size: 20,
                        color: selectedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(selectedCategory!.name),
                    ],
                  )
                : const Text('请选择分类', style: TextStyle(color: Colors.grey)),
          ),
        ),
        if (selectedCategory != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '自定义图标:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onPickCustomIcon,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: customIconPath != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(customIconPath!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: onRemoveCustomIcon,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          Icons.add,
                          size: 32,
                          color: Theme.of(context).hintColor,
                        ),
                ),
              ),
              if (customIconPath != null) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () =>
                      ImagePreviewDialog.show(context, customIconPath!),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('查看大图'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          return _CategorySheetContent(
            onCategorySelected: (cat) {
              onCategorySelected(cat);
            },
            selectedCategory: selectedCategory,
          );
        },
      ),
    );
  }
}

class _CategorySheetContent extends ConsumerStatefulWidget {
  final ValueChanged<Category?> onCategorySelected;
  final Category? selectedCategory;

  const _CategorySheetContent({
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  ConsumerState<_CategorySheetContent> createState() =>
      _CategorySheetContentState();
}

class _CategorySheetContentState extends ConsumerState<_CategorySheetContent> {
  late String _selectedMajor;
  late ScrollController _majorScrollController;
  final TextEditingController _searchController = TextEditingController();
  bool _selectionMade = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedMajor = CategoryConfig.hierarchy.keys.first;
    _majorScrollController = ScrollController();

    if (widget.selectedCategory != null) {
      final name = widget.selectedCategory!.name;
      if (widget.selectedCategory!.parentName != null) {
        _selectedMajor = widget.selectedCategory!.parentName!;
        // Robust check: if name is directly a Major Category, use it.
      } else if (CategoryConfig.hierarchy.containsKey(name)) {
        _selectedMajor = name;
      } else {
        _selectedMajor = CategoryConfig.getMajorCategory(name);
      }
    }

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _majorScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _confirmMajorCategory(List<Category> categoryTree) {
    final category = categoryTree.firstWhere(
      (item) => item.name == _selectedMajor,
      orElse: () => categoryTree.first,
    );

    _selectionMade = true;
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryTreeProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        final categoryTree = categoriesAsync.valueOrNull;
        if (categoryTree == null || categoryTree.isEmpty) return;

        if (didPop && !_selectionMade && widget.selectedCategory == null) {
          _confirmMajorCategory(categoryTree);
        } else if (didPop &&
            !_selectionMade &&
            widget.selectedCategory != null) {
          // Check if we navigated away from the original Major selection
          final originalMajor =
              widget.selectedCategory!.parentName ??
              CategoryConfig.getMajorCategory(widget.selectedCategory!.name);
          if (_selectedMajor != originalMajor) {
            _confirmMajorCategory(categoryTree);
          }
        }
      },
      child: Container(
        height: 600, // Increased height for search bar
        padding: const EdgeInsets.only(top: 16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索分类...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            categoriesAsync.maybeWhen(
              data: (categoryTree) {
                if (_searchText.isNotEmpty || categoryTree.isEmpty) {
                  return const SizedBox.shrink();
                }

                final majorCategories = categoryTree
                    .map((e) => e.name)
                    .toList();
                final selectedMajor = majorCategories.contains(_selectedMajor)
                    ? _selectedMajor
                    : majorCategories.first;

                return SizedBox(
                  height: 48,
                  child: ListView.separated(
                    controller: _majorScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: majorCategories.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final major = majorCategories[i];
                      final isSelected = major == selectedMajor;
                      return ChoiceChip(
                        label: Text(major),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedMajor = major);
                        },
                        avatar: Icon(
                          IconUtils.getIconData(categoryTree[i].iconPath),
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : CategoryConfig.majorCategoryColors[major],
                        ),
                      );
                    },
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            if (_searchText.isEmpty) const Divider(height: 32),

            // Level 2: Sub Categories OR Search Results
            Expanded(
              child: categoriesAsync.when(
                data: (categoryTree) {
                  final allCategories = categoryTree
                      .expand((category) => [category, ...category.children])
                      .toList();
                  List<Category> visualCategories;

                  if (_searchText.isNotEmpty) {
                    visualCategories = allCategories
                        .where(
                          (category) => category.name.contains(_searchText),
                        )
                        .toList();
                  } else {
                    final major = categoryTree.firstWhere(
                      (category) => category.name == _selectedMajor,
                      orElse: () => categoryTree.first,
                    );
                    visualCategories = major.children;
                  }

                  if (visualCategories.isEmpty) {
                    return Center(
                      child: Text(
                        _searchText.isNotEmpty ? '未找到相关分类' : '暂无此类目数据',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '搜索结果',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: visualCategories.map((category) {
                            final isOther = category.name == '其它';

                            // Improved selection check for scoped "Other"
                            final isSameId =
                                widget.selectedCategory?.id == category.id;
                            final isSameName =
                                widget.selectedCategory?.name == category.name;
                            final isScopedOther =
                                isOther &&
                                widget.selectedCategory?.parentName ==
                                    _selectedMajor;

                            final isSelected =
                                (widget.selectedCategory != null) &&
                                (isSameId ||
                                    (widget.selectedCategory!.id < 0 &&
                                        isSameName) ||
                                    isScopedOther);

                            final itemConfig = isOther
                                ? null
                                : CategoryConfig.getItem(category.name);

                            return ChoiceChip(
                              label: Text(category.name),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  _selectionMade = true;
                                  widget.onCategorySelected(category);
                                  Navigator.of(context).pop();
                                } else {
                                  // Deselect -> Revert to Major Category
                                  _confirmMajorCategory(categoryTree);
                                  Navigator.of(context).pop();
                                }
                              },
                              avatar: Icon(
                                IconUtils.getIconData(category.iconPath),
                                size: 18,
                                color: isOther
                                    ? Colors.grey
                                    : (itemConfig?.color ??
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(
                          height: 32 + MediaQuery.of(context).padding.bottom,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
