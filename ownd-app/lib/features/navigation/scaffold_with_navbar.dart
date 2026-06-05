import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/draggable_add_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../core/theme/app_colors.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    final index = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Only show FAB on Home (0) and Insights (1)
    final showFab = index == 0 || index == 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If not on Home, go to Home
        if (index != 0) {
          _onItemTapped(0, context);
          return;
        }

        // 2. Double back logic
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          AppToast.show(context, '再按一次退出应用');
          return;
        }

        // 3. Exit App
        await SystemNavigator.pop();
      },
      child: Stack(
        children: [
          Scaffold(
            body: SizedBox(key: ValueKey<int>(index), child: widget.child),
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.deepSpace.withValues(alpha: 0.85)
                        : AppColors.snow.withValues(alpha: 0.9),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (int idx) =>
                        _onItemTapped(idx, context),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.devices_outlined),
                        selectedIcon: Icon(Icons.devices),
                        label: '资产',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights_outlined),
                        selectedIcon: Icon(Icons.insights),
                        label: '统计',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: '我的',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showFab) const DraggableAddButton(),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/')) {
      if (location == '/') return 0;
      if (location.startsWith('/insights')) return 1;
      if (location.startsWith('/profile')) return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/insights');
        break;
      case 2:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
