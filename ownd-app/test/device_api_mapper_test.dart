import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/data/mappers/device_api_mapper.dart';
import 'package:ownd/data/models/device.dart';

void main() {
  test('deviceToApi includes imagePath for remote refresh', () {
    final device = Device()
      ..name = '相机'
      ..price = 10
      ..purchaseDate = DateTime(2026, 6, 24)
      ..imagePath = '/app/images/item.png';

    expect(deviceToApi(device)['imagePath'], '/app/images/item.png');
  });

  test('deviceToApi sends null imagePath so edits can remove photos', () {
    final device = Device()
      ..name = '相机'
      ..price = 10
      ..purchaseDate = DateTime(2026, 6, 24);

    expect(deviceToApi(device), containsPair('imagePath', null));
  });

  test('deviceToApi sends empty notes so edits can clear notes', () {
    final device = Device()
      ..name = '相机'
      ..price = 10
      ..purchaseDate = DateTime(2026, 6, 24)
      ..notes = '';

    expect(deviceToApi(device), containsPair('notes', ''));
  });
}
