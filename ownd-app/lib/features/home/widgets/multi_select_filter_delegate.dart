import 'package:flutter/material.dart';

class MultiSelectFilterDelegate extends SliverPersistentHeaderDelegate {
  final Set<String> selectedCategories;
  final List<String> categories;
  final ValueChanged<Set<String>> onSelectionChanged;

  MultiSelectFilterDelegate({
    required this.selectedCategories,
    required this.categories,
    required this.onSelectionChanged,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final allCategories = categories;
    // Logic: If selectedCategories size equals allCategories size, "All" is active logic-wise.
    // User requirement: "When 'All' is selected, all chips are active. Clicking 'All' again cancels all."
    // Actually, usually "All" is a separate chip.
    // Implementation:
    // 1. "All" Chip:
    //    - Active if selectedCategories contains ALL categories.
    //    - Tap: If active -> Clear selection. If inactive -> Select All.
    // 2. Category Chips:
    //    - Active if contained in selectedCategories.
    //    - Tap: Toggle.

    final isAllSelected = selectedCategories.length == allCategories.length;

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length + 1,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                // "All" Chip
                final isSelected = isAllSelected;
                return ChoiceChip(
                  label: const Text('全部'),
                  selected: isSelected,
                  showCheckmark: false,
                  padding: EdgeInsets.zero,
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  onSelected: (_) {
                    if (isSelected) {
                      // Deselect All (turns off all chips, effectively returning to show-all default)
                      onSelectionChanged({});
                    } else {
                      // Select All (turns on all chips, user can now deselect specific ones)
                      onSelectionChanged(allCategories.toSet());
                    }
                  },
                );
              }

              final category = allCategories[i - 1];
              final isSelected = selectedCategories.contains(category);

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                showCheckmark: false,
                padding: EdgeInsets.zero,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                onSelected: (val) {
                  final newSet = Set<String>.from(selectedCategories);
                  if (val) {
                    newSet.add(category);
                  } else {
                    newSet.remove(category);
                  }
                  onSelectionChanged(newSet);
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
  bool shouldRebuild(covariant MultiSelectFilterDelegate oldDelegate) {
    // Determine if rebuild needed. Set equality check using setEquals from flutter/foundation or logic?
    // Sets are not equal if different instances usually, but content check is better.
    // Simple length check + containsAll is enough.
    if (oldDelegate.selectedCategories.length != selectedCategories.length) {
      return true;
    }
    if (!oldDelegate.selectedCategories.containsAll(selectedCategories)) {
      return true;
    }
    if (oldDelegate.categories.length != categories.length) {
      return true;
    }
    return !oldDelegate.categories.every(categories.contains);
  }
}
