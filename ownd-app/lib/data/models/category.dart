import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  @Index()
  String? uuid;

  late String iconPath;

  bool isDefault = false;

  @ignore
  String? parentUuid;

  @ignore
  String? parentName;

  @ignore
  List<Category> children = [];
}
