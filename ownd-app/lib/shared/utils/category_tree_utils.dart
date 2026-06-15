import '../../data/models/category.dart';
import '../config/category_config.dart';

class CategoryTreeUtils {
  const CategoryTreeUtils._();

  static List<Category> sortTree(List<Category> categories) {
    final sorted = [...categories]..sort(_compareCategories);
    for (final category in sorted) {
      category.children = sortTree(category.children);
    }
    return sorted;
  }

  static List<Category> flattenTree(List<Category> categories) {
    return [
      for (final category in categories) ...[
        category,
        ...flattenTree(category.children),
      ],
    ];
  }

  static String majorCategoryFor(Category? category) {
    if (category == null) return '其它';
    if (category.name == '虚拟订阅') return '虚拟订阅';
    if (category.parentName == '虚拟订阅') return '虚拟订阅';
    if (CategoryConfig.subscriptionGroupNames.contains(category.parentName)) {
      return '虚拟订阅';
    }

    final configuredMajor = CategoryConfig.getMajorCategory(category.name);
    if (configuredMajor == '虚拟订阅') return '虚拟订阅';

    final parentName = category.parentName;
    if (parentName != null &&
        CategoryConfig.hierarchy.containsKey(parentName)) {
      return parentName;
    }

    return configuredMajor;
  }

  static bool isVirtualSubscription(Category? category) {
    return majorCategoryFor(category) == '虚拟订阅';
  }

  static int _compareCategories(Category a, Category b) {
    final aOther = a.name == '其它';
    final bOther = b.name == '其它';
    if (aOther != bOther) return aOther ? 1 : -1;

    final aIndex = _categoryOrder(a.name);
    final bIndex = _categoryOrder(b.name);
    if (aIndex != bIndex) return aIndex.compareTo(bIndex);

    return a.name.compareTo(b.name);
  }

  static int _categoryOrder(String name) {
    final majorIndex = CategoryConfig.hierarchy.keys.toList().indexOf(name);
    if (majorIndex >= 0) return majorIndex;

    final itemIndex = CategoryConfig.defaultCategories.indexWhere(
      (item) => item.name == name,
    );
    if (itemIndex >= 0) return 100 + itemIndex;

    return 10000;
  }
}
