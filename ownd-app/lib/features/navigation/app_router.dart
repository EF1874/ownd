import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scaffold_with_navbar.dart';
import '../../features/home/home_screen.dart';
import '../../features/add_device/add_device_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/account_profile_screen.dart';
import '../../features/dashboard/insights_screen.dart';
import '../../features/device_detail/device_detail_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final session = authState.asData?.value;
      final isLoginRoute = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isLoginRoute ? null : '/login';
      }

      if (session == null) {
        return isLoginRoute ? null : '/login';
      }

      if (isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/account',
            builder: (context, state) => const AccountProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddDeviceScreen(),
      ),
      GoRoute(
        path: '/device/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          return DeviceDetailScreen(id: id);
        },
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, __) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});
