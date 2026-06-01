import 'package:flutter/material.dart';
import '../../../shared/config/category_config.dart';

class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  StickyFilterDelegate({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryConfig.hierarchy.length + 1,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final isAll = i == 0;
              final key = isAll
                  ? '全部'
                  : CategoryConfig.hierarchy.keys.elementAt(i - 1);
              final isSelected = selectedCategory == (isAll ? null : key);
              return ChoiceChip(
                label: Text(key),
                selected: isSelected,
                showCheckmark: false,
                padding: EdgeInsets.zero,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                onSelected: (_) {
                  if (isAll) {
                    onCategorySelected(null);
                  } else {
                    if (selectedCategory == key) {
                      onCategorySelected(null); // Toggle off
                    } else {
                      onCategorySelected(key);
                    }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant StickyFilterDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory;
  }
}
