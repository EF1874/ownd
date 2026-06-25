import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/error_messages.dart';
import '../../data/services/preferences_service.dart';
import '../../shared/services/app_update_service.dart';
import '../../shared/widgets/app_update_prompt.dart';
import '../../shared/widgets/draggable_add_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../core/theme/app_colors.dart';
import 'navigation_provider.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  DateTime? _lastPressedAt;
  bool _autoUpdateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdateOncePerDay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showBottomNavBar = !keyboardVisible;

    // Only show FAB on Home (0) and Insights (1)
    final showFab = (index == 0 || index == 1) && !keyboardVisible;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If not on Home, go to Home
        if (index != 0) {
          final guard = ref.read(routeLeaveGuardProvider);
          if (guard != null && !await guard()) return;
          if (!context.mounted) return;

          final path = GoRouterState.of(context).uri.path;
          if (path.startsWith('/profile/')) {
            GoRouter.of(context).go('/profile');
            return;
          }

          GoRouter.of(context).go('/');
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
            bottomNavigationBar: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: showBottomNavBar
                  ? _BottomNavigationBarSurface(
                      isDark: isDark,
                      selectedIndex: index,
                      onDestinationSelected: (idx) {
                        _onItemTapped(idx, context);
                      },
                    )
                  : const SizedBox.shrink(),
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

  Future<void> _onItemTapped(int index, BuildContext context) async {
    final guard = ref.read(routeLeaveGuardProvider);
    if (guard != null && !await guard()) return;
    if (!context.mounted) return;

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

  Future<void> _checkForUpdateOncePerDay() async {
    if (_autoUpdateCheckStarted || !mounted) {
      return;
    }
    _autoUpdateCheckStarted = true;

    final preferences = ref.read(preferencesServiceProvider);
    if (preferences.hasCheckedAppUpdateToday()) {
      return;
    }

    await preferences.setAppUpdateCheckedToday();
    try {
      final result = await ref.read(appUpdateServiceProvider).checkForUpdate();
      if (!mounted || !result.hasUpdate) {
        return;
      }

      showAppUpdateDialog(context, ref, result.latest);
    } catch (e) {
      debugPrint('Daily update check failed: ${userErrorMessage(e)}');
    }
  }
}

class _BottomNavigationBarSurface extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavigationBarSurface({
    required this.isDark,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.deepSpace.withValues(alpha: 0.85)
                : AppColors.snow.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
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
    );
  }
}
