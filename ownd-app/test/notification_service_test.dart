import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/shared/services/notification_service.dart';

void main() {
  test('badge count tracks notification ids without duplicates', () {
    expect(NotificationService.notificationBadgeCountAfterShow([1, 2], 2), 2);
    expect(NotificationService.notificationBadgeCountAfterShow([1, 2], 3), 3);
    expect(
      NotificationService.notificationBadgeCountAfterCancel([1, 2, 3], 2),
      2,
    );
  });
}
