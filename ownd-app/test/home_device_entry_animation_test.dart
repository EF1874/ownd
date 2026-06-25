import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/features/home/widgets/device_list_item.dart';

void main() {
  test('device entry animation only plays once per device id', () {
    const id = 987654321;

    expect(shouldPlayDeviceEntryAnimation(id), isTrue);
    expect(shouldPlayDeviceEntryAnimation(id), isFalse);
  });
}
