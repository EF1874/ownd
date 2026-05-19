import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../datasource/category_datasource.dart';
import '../datasource/remote/remote_category_datasource.dart';
import '../../shared/config/category_config.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';

/// Riverpod provider for the CategoryDataSource.
final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
  return RemoteCategoryDataSource(ref.watch(apiClientProvider));
});

/// Riverpod provider for the CategoryRepository.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dataSource = ref.watch(categoryDataSourceProvider);
  return CategoryRepository(dataSource);
});

final categoryTreeProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getCategoryTree();
});

/// Repository layer for Category entities.
class CategoryRepository {
  final CategoryDataSource _dataSource;

  CategoryRepository(this._dataSource);

  Future<List<Category>> getAllCategories() async {
    final categories = List<Category>.from(await _dataSource.getAll());

    // Sort based on the order in CategoryConfig.defaultCategories
    final orderMap = {
      for (var i = 0; i < CategoryConfig.defaultCategories.length; i++)
        CategoryConfig.defaultCategories[i].name: i,
    };

    categories.sort((a, b) {
      final indexA = orderMap[a.name] ?? 999;
      final indexB = orderMap[b.name] ?? 999;
      return indexA.compareTo(indexB);
    });

    return categories;
  }

  Future<List<Category>> getCategoryTree() => _dataSource.getTree();

  Future<int> addCategory(Category category) => _dataSource.add(category);

  Future<Category> ensureCategory(String name, {Category? parent}) async {
    final existing = await findCategoryByName(name, parent: parent);
    if (existing != null) return existing;

    final newCat = Category()
      ..name = name
      ..iconPath = 'MdiIcons.tag'
      ..isDefault = false
      ..parentUuid = parent?.parentUuid ?? parent?.uuid
      ..parentName = parent?.parentName ?? parent?.name;

    final id = await addCategory(newCat);
    newCat.id = id;
    return newCat;
  }

  Future<Category?> findCategoryByName(String name, {Category? parent}) async {
    final categories = await _dataSource.getAll();
    final parentUuid = parent?.parentUuid ?? parent?.uuid;

    for (final category in categories) {
      if (category.name != name) continue;
      if (parent == null || category.parentUuid == parentUuid) {
        return category;
      }
    }

    return null;
  }

  Future<void> deleteCategory(int id) => _dataSource.delete(id);

  Future<void> initDefaultCategories() async {
    final defaults = CategoryConfig.defaultCategories.map((item) {
      return Category()
        ..uuid = const Uuid().v4()
        ..name = item.name
        ..iconPath = item.iconPath
        ..isDefault = true;
    }).toList();

    await _dataSource.initDefaults(defaults);
  }
}
