import 'package:isar/isar.dart';
import '../../models/category.dart';
import '../category_datasource.dart';

/// Isar-based local implementation of [CategoryDataSource].
class IsarCategoryDataSource implements CategoryDataSource {
  final Isar _isar;

  IsarCategoryDataSource(this._isar);

  @override
  Future<List<Category>> getAll() async {
    return await _isar.categorys.where().findAll();
  }

  @override
  Future<List<Category>> getTree() async {
    return await getAll();
  }

  @override
  Future<Id> add(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  @override
  Future<Category?> findByName(String name) async {
    return await _isar.categorys.filter().nameEqualTo(name).findFirst();
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(id);
    });
  }

  @override
  Future<void> initDefaults(List<Category> defaults) async {
    final configNames = defaults.map((e) => e.name).toSet();
    final existingCategories = await _isar.categorys.where().findAll();

    await _isar.writeTxn(() async {
      // Delete categories not in config
      for (final category in existingCategories) {
        if (!configNames.contains(category.name)) {
          await _isar.categorys.delete(category.id);
        }
      }

      // Add or update categories from config
      for (final item in defaults) {
        final existing = await _isar.categorys
            .filter()
            .nameEqualTo(item.name)
            .findFirst();

        if (existing == null) {
          await _isar.categorys.put(item);
        } else {
          existing.iconPath = item.iconPath;
          await _isar.categorys.put(existing);
        }
      }
    });
  }
}
