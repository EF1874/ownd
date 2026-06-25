import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RouteLeaveGuard = Future<bool> Function();

final bottomNavBarVisibleProvider = StateProvider<bool>((ref) => true);
final routeLeaveGuardProvider = StateProvider<RouteLeaveGuard?>((ref) => null);
