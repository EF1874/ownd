import '../models/category.dart';
import 'api_id_mapper.dart';

Category categoryFromApi(Map<String, dynamic> json) {
  return Category()
    ..id = stableIntId(json['id'] as String)
    ..uuid = json['id'] as String
    ..name = json['name'] as String
    ..iconPath = (json['icon'] as String?) ?? 'MdiIcons.tag'
    ..isDefault = json['userId'] == null;
}

Map<String, dynamic> categoryToApi(Category category) {
  return {'name': category.name, 'icon': category.iconPath};
}
