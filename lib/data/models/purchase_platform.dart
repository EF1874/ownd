class PurchasePlatform {
  final int id;
  final String uuid;
  final String name;
  final String iconPath;
  final String colorHex;
  final bool isDefault;

  const PurchasePlatform({
    required this.id,
    required this.uuid,
    required this.name,
    required this.iconPath,
    required this.colorHex,
    required this.isDefault,
  });
}
