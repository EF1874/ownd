// ignore_for_file: invalid_use_of_protected_member

part of '../dashboard_screen.dart';

extension _DashboardFilters on _DashboardContentState {
  // ─── Time Filtering ─────────────────────────────────────────
  List<Device> _filterDevices(List<Device> devices) {
    final now = DateTime.now();
    switch (_timeFilter) {
      case DashboardTimeFilter.all:
        return devices;
      case DashboardTimeFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return devices
            .where(
              (d) => d.purchaseDate.isAfter(
                DateTime(weekStart.year, weekStart.month, weekStart.day),
              ),
            )
            .toList();
      case DashboardTimeFilter.thisMonth:
        return devices
            .where(
              (d) =>
                  d.purchaseDate.year == now.year &&
                  d.purchaseDate.month == now.month,
            )
            .toList();
      case DashboardTimeFilter.thisQuarter:
        final qStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return devices
            .where(
              (d) => d.purchaseDate.isAfter(
                qStart.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
      case DashboardTimeFilter.thisHalf:
        final hStart = DateTime(now.year, now.month <= 6 ? 1 : 7, 1);
        return devices
            .where(
              (d) => d.purchaseDate.isAfter(
                hStart.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
      case DashboardTimeFilter.thisYear:
        return devices.where((d) => d.purchaseDate.year == now.year).toList();
      case DashboardTimeFilter.custom:
        if (_customRange == null) return devices;
        return devices
            .where(
              (d) =>
                  d.purchaseDate.isAfter(
                    _customRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  d.purchaseDate.isBefore(
                    _customRange!.end.add(const Duration(days: 1)),
                  ),
            )
            .toList();
    }
  }

  String _filterLabel(DashboardTimeFilter f) {
    switch (f) {
      case DashboardTimeFilter.all:
        return '全部';
      case DashboardTimeFilter.thisWeek:
        return '本周';
      case DashboardTimeFilter.thisMonth:
        return '本月';
      case DashboardTimeFilter.thisQuarter:
        return '本季度';
      case DashboardTimeFilter.thisHalf:
        return '半年';
      case DashboardTimeFilter.thisYear:
        return '本年';
      case DashboardTimeFilter.custom:
        return '自定义范围';
    }
  }

  void _showEnhancedDateRangePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhancedDateRangePicker(
        initialRange: _customRange,
        onSelected: (range) {
          setState(() {
            _customRange = range;
            _timeFilter = DashboardTimeFilter.custom;
            touchedPieIndex = -1;
            selectedPieKey = null;
          });
        },
      ),
    );
  }
}
