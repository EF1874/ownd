import 'package:isar/isar.dart';

import '../../../core/network/api_client.dart';
import '../../mappers/category_api_mapper.dart';
import '../../models/category.dart';
import '../category_datasource.dart';

class RemoteCategoryDataSource implements CategoryDataSource {
  final ApiClient _apiClient;
  List<Category> _cache = [];

  RemoteCategoryDataSource(this._apiClient);

  @override
  Future<List<Category>> getAll() async {
    final data = await _apiClient.get<List<dynamic>>('/categories');
    _cache = data
        .whereType<Map<String, dynamic>>()
        .expand(_flattenCategory)
        .map(categoryFromApi)
        .toList();
    return List.unmodifiable(_cache);
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

  Iterable<Map<String, dynamic>> _flattenCategory(Map<String, dynamic> json) {
    return [
      json,
      ...((json['children'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .expand(_flattenCategory),
    ];
  }
}
