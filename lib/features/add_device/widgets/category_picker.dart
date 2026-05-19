import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/widgets/image_preview_dialog.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getAllCategories();
});

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
      // Robust check: if name is directly a Major Category, use it.
      if (CategoryConfig.hierarchy.containsKey(name)) {
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

  void _confirmMajorCategory() {
    // Construct a Category object for the Major Category
    final iconPath =
        CategoryConfig.majorCategoryIconStrings[_selectedMajor] ??
        'MdiIcons.shape';

    final category = Category()
      ..name = _selectedMajor
      ..iconPath = iconPath
      ..id = -2;

    _selectionMade = true;
    widget.onCategorySelected(category);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final majorCategories = CategoryConfig.hierarchy.keys.toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_selectionMade && widget.selectedCategory == null) {
          _confirmMajorCategory();
        } else if (didPop &&
            !_selectionMade &&
            widget.selectedCategory != null) {
          // Check if we navigated away from the original Major selection
          final originalMajor = CategoryConfig.getMajorCategory(
            widget.selectedCategory!.name,
          );
          if (_selectedMajor != originalMajor) {
            _confirmMajorCategory();
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

            // If searching, hide tabs
            if (_searchText.isEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  controller: _majorScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: majorCategories.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final major = majorCategories[i];
                    final isSelected = major == _selectedMajor;
                    return ChoiceChip(
                      label: Text(major),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMajor = major);
                      },
                      avatar: Icon(
                        CategoryConfig.majorCategoryIcons[major] ??
                            Icons.circle,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : CategoryConfig.majorCategoryColors[major],
                      ),
                    );
                  },
                ),
              ),

            if (_searchText.isEmpty) const Divider(height: 32),

            // Level 2: Sub Categories OR Search Results
            Expanded(
              child: categoriesAsync.when(
                data: (allCategories) {
                  List<String> displayNames;

                  if (_searchText.isNotEmpty) {
                    // Search Mode: Filter all config categories
                    displayNames = CategoryConfig.defaultCategories
                        .where((c) => c.name.contains(_searchText))
                        .map((c) => c.name)
                        .toList();
                  } else {
                    // Standard Mode: Filter by Major
                    final subNames =
                        CategoryConfig.hierarchy[_selectedMajor] ?? [];
                    displayNames = List<String>.from(subNames);
                    if (!displayNames.contains('其它')) {
                      displayNames.add('其它');
                    }
                  }

                  final visualCategories = displayNames.map((name) {
                    // Try to find existing category from DB
                    final found = allCategories.firstWhere(
                      (c) => c.name == name,
                      orElse: () => Category()
                        ..name = name
                        ..iconPath = CategoryConfig.getItem(name).iconPath
                        ..id = -1,
                    );
                    // Fix icon for Other
                    if (name == '其它') {
                      found.iconPath = 'MdiIcons.dotsHorizontal';
                    }
                    return found;
                  }).toList();

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
                                widget.selectedCategory?.name ==
                                    '$_selectedMajor-其它';

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
                                  if (isOther) {
                                    // Construct scoped Other category
                                    final scopedOther = Category()
                                      ..name = '$_selectedMajor-其它'
                                      ..iconPath = 'MdiIcons.dotsHorizontal'
                                      ..id = -1;
                                    widget.onCategorySelected(scopedOther);
                                  } else {
                                    widget.onCategorySelected(category);
                                  }
                                  Navigator.of(context).pop();
                                } else {
                                  // Deselect -> Revert to Major Category
                                  _confirmMajorCategory();
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
