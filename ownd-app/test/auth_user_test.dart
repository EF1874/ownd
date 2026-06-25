import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/data/models/auth_user.dart';

void main() {
  test('parses avatar path from profile response', () {
    final user = AuthUser.fromJson({
      'id': '1',
      'email': 'test@example.com',
      'name': 'Test',
      'avatarPath': '/ownd-items/avatar.png',
    });

    expect(user.avatarPath, '/ownd-items/avatar.png');
    expect(user.notificationLeadDays, 3);
    expect(user.notificationTime, '08:00');
  });
}
