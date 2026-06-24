import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/shared/utils/subscription_utils.dart';

void main() {
  test('daysUntilDue includes the due day', () {
    final today = DateTime(2026, 6, 24, 12);

    expect(
      SubscriptionUtils.daysUntilDue(DateTime(2026, 6, 24), from: today),
      1,
    );
    expect(
      SubscriptionUtils.daysUntilDue(DateTime(2026, 6, 25), from: today),
      2,
    );
    expect(
      SubscriptionUtils.daysUntilDue(DateTime(2026, 6, 23), from: today),
      -1,
    );
  });
}
