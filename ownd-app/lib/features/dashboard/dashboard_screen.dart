import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../home/home_screen.dart'; // for deviceListProvider
import '../../data/models/device.dart';
import '../../core/network/error_messages.dart';
import '../../shared/utils/format_utils.dart';

part 'widgets/dashboard_filters.dart';
part 'widgets/dashboard_overview.dart';
part 'widgets/dashboard_trends.dart';
part 'widgets/dashboard_date_picker.dart';

/// Extended time filter enum
enum DashboardTimeFilter {
  all,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisHalf,
  thisYear,
  custom,
}

enum PieGroupBy { category, tag }

enum TrendType { bar, line }

/// DashboardContent — designed to live inside a TabBarView
class DashboardContent extends ConsumerStatefulWidget {
  const DashboardContent({super.key});

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent>
    with AutomaticKeepAliveClientMixin {
  int touchedPieIndex = -1;
  String? selectedPieKey;
  DashboardTimeFilter _timeFilter = DashboardTimeFilter.all;
  PieGroupBy _pieGroupBy = PieGroupBy.category;
  TrendType _trendType = TrendType.bar;
  DateTimeRange? _customRange;
  String? _expandedRankingKey; // Format: "price_0" or "cost_2"

  @override
  bool get wantKeepAlive => true;

  // ─── Semantic Card Colors ───────────────────────────────────
  // 4 distinct, pleasant tones for the overview grid
  static const Color _assetColor = Color(0xFF2196F3); // Calm blue — asset value
  static const Color _countColor = Color(0xFF26A69A); // Teal — count
  static const Color _monthlyColor = Color(
    0xFFFFA726,
  ); // Warm amber — monthly burn
  static const Color _dailyColor = Color(
    0xFFEF5350,
  ); // Soft red — daily burn (warning)

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final devicesAsyncValue = ref.watch(deviceListProvider);
    final theme = Theme.of(context);

    return devicesAsyncValue.when(
      data: (devices) {
        final activeDevices = devices
            .where((d) => d.status != 'scrap')
            .toList();
        if (activeDevices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无活跃数据可以分析',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final filteredDevices = _filterDevices(activeDevices);

        double totalValue = 0;
        double dailyCostTotal = 0;
        Map<String, double> categoryValues = {};
        Map<String, double> tagValues = {};

        for (var device in filteredDevices) {
          totalValue += device.price;
          dailyCostTotal += (device.dailyCost);

          final catName = device.category.value?.name ?? '未分类';
          categoryValues[catName] =
              (categoryValues[catName] ?? 0.0) + (device.price);

          if (device.tags.isEmpty) {
            tagValues['无标签'] = (tagValues['无标签'] ?? 0.0) + (device.price);
          } else {
            for (var tag in device.tags) {
              tagValues[tag] = (tagValues[tag] ?? 0.0) + (device.price);
            }
          }
        }

        final monthlyCostTotal = dailyCostTotal * 30;
        final pieData = _pieGroupBy == PieGroupBy.category
            ? categoryValues
            : tagValues;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Time Filter Chips ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...DashboardTimeFilter.values
                          .where((f) => f != DashboardTimeFilter.custom)
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_filterLabel(f)),
                                selected: _timeFilter == f,
                                onSelected: (_) {
                                  setState(() {
                                    _timeFilter = f;
                                    touchedPieIndex = -1;
                                    selectedPieKey = null;
                                  });
                                },
                              ),
                            ),
                          ),
                      ChoiceChip(
                        avatar: Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: _timeFilter == DashboardTimeFilter.custom
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                        label: Text(
                          _timeFilter == DashboardTimeFilter.custom &&
                                  _customRange != null
                              ? '${FormatUtils.formatDateShort(_customRange!.start)} - ${FormatUtils.formatDateShort(_customRange!.end)}'
                              : '自定义周期',
                        ),
                        selected: _timeFilter == DashboardTimeFilter.custom,
                        onSelected: (selected) {
                          if (selected) {
                            _showEnhancedDateRangePicker();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ─── Content ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (filteredDevices.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          '选定周期内无新增设备',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    _buildGridOverview(
                      totalValue,
                      filteredDevices.length,
                      monthlyCostTotal,
                      dailyCostTotal,
                      theme,
                    ),

                    const SizedBox(height: 32),
                    _buildPieGroupToggle(theme),
                    const SizedBox(height: 12),
                    _buildInteractivePieChart(pieData, filteredDevices, theme),

                    const SizedBox(height: 32),
                    _buildTrendHeader(theme),
                    const SizedBox(height: 16),
                    _trendType == TrendType.bar
                        ? _buildMonthlyTrendChart(filteredDevices, theme)
                        : _buildMonthlyTrendLineChart(filteredDevices, theme),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      '高价值资产 Top 5',
                      Icons.workspace_premium_rounded,
                      theme,
                      color: _assetColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTopRanking(filteredDevices, theme, isByPrice: true),

                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      '日均成本 "刺客" 警示榜',
                      Icons.warning_rounded,
                      theme,
                      color: _dailyColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTopRanking(filteredDevices, theme, isByPrice: false),

                    const SizedBox(height: 60),
                  ],
                ]),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('加载失败: ${userErrorMessage(error)}')),
    );
  }

  // ─── Section Header ─────────────────────────────────────────
}
