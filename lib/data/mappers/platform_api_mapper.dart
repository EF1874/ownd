import '../models/purchase_platform.dart';
import 'api_id_mapper.dart';

PurchasePlatform platformFromApi(Map<String, dynamic> json) {
  return PurchasePlatform(
    id: stableIntId(json['id'] as String),
    uuid: json['id'] as String,
    name: json['name'] as String,
    iconPath: json['icon'] as String? ?? 'MdiIcons.store',
    colorHex: json['color'] as String? ?? '#9E9E9E',
    isDefault: json['userId'] == null,
  );
}

Map<String, dynamic> platformToApi(String name) {
  return {'name': name, 'icon': 'MdiIcons.store', 'color': '#9E9E9E'};
}
