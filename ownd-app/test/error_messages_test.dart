import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/core/network/error_messages.dart';

void main() {
  test('version mismatch validation errors stay user friendly', () {
    expect(
      userErrorMessage(Exception('nextBillingDate should not exist')),
      '应用和服务版本不一致，请更新应用或重启服务后重试',
    );
  });
}
