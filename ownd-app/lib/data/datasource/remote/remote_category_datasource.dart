import 'package:isar/isar.dart';

import '../../../core/network/api_client.dart';
import '../../mappers/category_api_mapper.dart';
import '../../models/category.dart';
import '../category_datasource.dart';

class RemoteCategoryDataSource implements CategoryDataSource {
  final ApiClient _apiClient;
  List<Category> _cache = [];
  List<Category> _treeCache = [];

  RemoteCategoryDataSource(this._apiClient);

  @override
  Future<List<Category>> getAll() async {
    final tree = await getTree();
    _cache = tree.expand(_flattenCategoryNode).toList();
    return List.unmodifiable(_cache);
  }

  @override
  Future<List<Category>> getTree() async {
    final data = await _apiClient.get<List<dynamic>>('/categories');
    _treeCache = data
        .whereType<Map<String, dynamic>>()
        .map(categoryTreeFromApi)
        .toList();
    _cache = _treeCache.expand(_flattenCategoryNode).toList();
    return List.unmodifiable(_treeCache);
  }

  @override
  Future<Id> add(Category category) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/categories',
      data: categoryToApi(category),
    );
    final created = categoryFromApi(data);
    category
      ..id = created.id
      ..uuid = created.uuid
      ..iconPath = created.iconPath;
    await getAll();
    return created.id;
  }

  @override
  Future<void> delete(int id) async {
    final category = _cache.firstWhere((item) => item.id == id);
    await _apiClient.delete<dynamic>('/categories/${category.uuid}');
    await getAll();
  }

  @override
  Future<Category?> findByName(String name) async {
    if (_cache.isEmpty) await getAll();
    for (final category in _cache) {
      if (category.name == name) return category;
    }
    return null;
  }

  @override
  Future<void> initDefaults(List<Category> defaults) async {
    final existing = await getAll();
    final existingNames = existing.map((item) => item.name).toSet();

    for (final category in defaults) {
      if (!existingNames.contains(category.name)) {
        await add(category);
      }
    }
  }

  Iterable<Category> _flattenCategoryNode(Category category) {
    return [category, ...category.children.expand(_flattenCategoryNode)];
  }
}
