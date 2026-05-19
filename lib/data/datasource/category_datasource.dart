import 'package:isar/isar.dart';
import '../models/category.dart';

/// Abstract data source interface for Category entities.
abstract class CategoryDataSource {
  Future<List<Category>> getAll();
  Future<List<Category>> getTree();
  Future<Id> add(Category category);
  Future<Category?> findByName(String name);
  Future<void> delete(int id);

  /// Initialize or sync default categories in the local store.
  Future<void> initDefaults(List<Category> defaults);
}
