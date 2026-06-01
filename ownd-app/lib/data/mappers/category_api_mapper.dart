import '../models/category.dart';
import 'api_id_mapper.dart';

Category categoryFromApi(Map<String, dynamic> json) {
  final parentJson = json['parent'];
  return Category()
    ..id = stableIntId(json['id'] as String)
    ..uuid = json['id'] as String
    ..name = json['name'] as String
    ..iconPath = (json['icon'] as String?) ?? 'MdiIcons.tag'
    ..isDefault = json['userId'] == null
    ..parentUuid = json['parentId'] as String?
    ..parentName = parentJson is Map<String, dynamic>
        ? parentJson['name'] as String?
        : null;
}

Category categoryTreeFromApi(
  Map<String, dynamic> json, {
  String? parentUuid,
  String? parentName,
}) {
  final category = categoryFromApi(json)
    ..parentUuid = parentUuid ?? json['parentId'] as String?
    ..parentName = parentName;

  category.children = ((json['children'] as List<dynamic>?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(
        (child) => categoryTreeFromApi(
          child,
          parentUuid: category.uuid,
          parentName: category.name,
        ),
      )
      .toList();

  return category;
}

Map<String, dynamic> categoryToApi(Category category) {
  return {
    'name': category.name,
    'icon': category.iconPath,
    if (category.parentUuid != null) 'parentId': category.parentUuid,
  };
}
