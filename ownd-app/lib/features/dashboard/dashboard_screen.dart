import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../home/home_screen.dart'; // for deviceListProvider
import '../../data/models/device.dart';
import '../../core/network/error_messages.dart';
import '../../shared/utils/format_utils.dart';

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
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ThemeData theme, {
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(color: c)),
      ],
    );
  }

  // ─── 2x2 Grid with 4 semantic colors ─────────────────────
  Widget _buildGridOverview(
    double totalValue,
    int count,
    double monthlyCost,
    double dailyCost,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRichStatCard(
                '当前账面余值',
                '¥${FormatUtils.formatCurrency(totalValue)}',
                _assetColor,
                Icons.account_balance_wallet_rounded,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRichStatCard(
                '实物保管件数',
                '$count 件',
                _countColor,
                Icons.devices_other_rounded,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRichStatCard(
                '推演折损月耗',
                '¥${FormatUtils.formatCurrency(monthlyCost)}',
                _monthlyColor,
                Icons.calendar_month_rounded,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRichStatCard(
                '推演折损日耗',
                '¥${FormatUtils.formatCurrency(dailyCost)}',
                _dailyColor,
                Icons.today_rounded,
                theme,
                isWarning: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRichStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
    ThemeData theme, {
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Pie Group Toggle (Category / Tag) ──────────────────
  Widget _buildPieGroupToggle(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.pie_chart_rounded,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 8),
        Text('资产分布', style: theme.textTheme.titleMedium),
        const Spacer(),
        SegmentedButton<PieGroupBy>(
          segments: const [
            ButtonSegment(value: PieGroupBy.category, label: Text('按分类')),
            ButtonSegment(value: PieGroupBy.tag, label: Text('按标签')),
          ],
          selected: {_pieGroupBy},
          onSelectionChanged: (v) {
            setState(() {
              _pieGroupBy = v.first;
              touchedPieIndex = -1;
              selectedPieKey = null;
            });
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
          ),
        ),
      ],
    );
  }

  // ─── Pie Chart (reusable for both category and tag) ─────
  Widget _buildInteractivePieChart(
    Map<String, double> dataMap,
    List<Device> allDevices,
    ThemeData theme,
  ) {
    if (dataMap.isEmpty) return const SizedBox();

    // Pleasing distinguishable palette (HSL based, constant saturation)
    final List<Color> palette = [
      const Color(0xFF5C6BC0), // indigo
      const Color(0xFF26A69A), // teal
      const Color(0xFFFFA726), // amber
      const Color(0xFFEF5350), // red
      const Color(0xFF66BB6A), // green
      const Color(0xFFAB47BC), // purple
      const Color(0xFF42A5F5), // light blue
      const Color(0xFFEC407A), // pink
    ];

    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final double total = dataMap.values.fold(0.0, (a, b) => a + b);

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final isTouched = i == touchedPieIndex;
      final color = palette[i % palette.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: sortedEntries[i].value,
          title: isTouched
              ? '${((sortedEntries[i].value / total) * 100).toStringAsFixed(1)}%'
              : '',
          radius: isTouched ? 50.0 : 40.0,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          borderSide: isTouched
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      );
    }

    // Determine what devices match the selected pie key
    List<Device> selectedDevices = [];
    if (selectedPieKey != null) {
      if (_pieGroupBy == PieGroupBy.category) {
        selectedDevices = allDevices
            .where((d) => (d.category.value?.name ?? '未分类') == selectedPieKey)
            .toList();
      } else {
        selectedDevices = allDevices.where((d) {
          if (selectedPieKey == '无标签') return d.tags.isEmpty;
          return d.tags.contains(selectedPieKey);
        }).toList();
      }
    }

    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event.runtimeType.toString() == 'FlTapUpEvent') {
                          if (pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final idx = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                          if (idx < 0 || idx >= sortedEntries.length) {
                            return;
                          }
                          setState(() {
                            if (touchedPieIndex == idx) {
                              touchedPieIndex = -1;
                              selectedPieKey = null;
                            } else {
                              touchedPieIndex = idx;
                              selectedPieKey = sortedEntries[idx].key;
                            }
                          });
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 220, // Explicit height reinforcement
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      for (int index = 0; index < sortedEntries.length; index++)
                        () {
                          final entry = sortedEntries[index];
                          final color = palette[index % palette.length];
                          final isTouched = index == touchedPieIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (touchedPieIndex == index) {
                                  touchedPieIndex = -1;
                                  selectedPieKey = null;
                                } else {
                                  touchedPieIndex = index;
                                  selectedPieKey = entry.key;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              margin: const EdgeInsets.only(
                                bottom: 2,
                                right: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isTouched
                                    ? color.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _pieGroupBy == PieGroupBy.tag
                                          ? '#${entry.key}'
                                          : entry.key,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: isTouched
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isTouched
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selectedPieKey != null && selectedDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.zoom_in,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_pieGroupBy == PieGroupBy.tag ? "标签" : "类别"}明细: $selectedPieKey',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...selectedDevices.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '•',
                                style: TextStyle(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '¥${FormatUtils.formatCurrency(d.price)}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Trend Header (with Toggle) ────────────────────────
  Widget _buildTrendHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.trending_up_rounded,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 8),
        Text('费用趋势', style: theme.textTheme.titleMedium),
        const Spacer(),
        SegmentedButton<TrendType>(
          segments: const [
            ButtonSegment(
              value: TrendType.bar,
              icon: Icon(Icons.bar_chart_rounded, size: 16),
            ),
            ButtonSegment(
              value: TrendType.line,
              icon: Icon(Icons.show_chart_rounded, size: 16),
            ),
          ],
          selected: {_trendType},
          onSelectionChanged: (v) => setState(() => _trendType = v.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Monthly Trend Line Chart ──────────────────────────
  Widget _buildMonthlyTrendLineChart(List<Device> devices, ThemeData theme) {
    // Group by month for last 6 months
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthData = [];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = '${date.month}月';
      final value = devices
          .where(
            (d) =>
                d.purchaseDate.year == date.year &&
                d.purchaseDate.month == date.month,
          )
          .fold(0.0, (sum, d) => sum + d.price);
      monthData.add({'label': label, 'value': value});
    }

    double maxVal = monthData
        .map((e) => e['value'] as double)
        .fold(0.0, (m, e) => e > m ? e : m);
    if (maxVal == 0) maxVal = 1000;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= monthData.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthData[value.toInt()]['label'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                monthData.length,
                (i) => FlSpot(i.toDouble(), monthData[i]['value'] as double),
              ),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.blueAccent,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.cyan.withValues(alpha: 0.4),
                    Colors.cyan.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map(
                      (s) => LineTooltipItem(
                        '¥${FormatUtils.formatCurrency(s.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Monthly Trend Bar Chart ────────────────────────────
  Widget _buildMonthlyTrendChart(List<Device> devices, ThemeData theme) {
    if (devices.isEmpty) {
      return const SizedBox();
    }

    final now = DateTime.now();
    final List<Map<String, dynamic>> monthData = [];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      double sum = 0;
      for (var d in devices) {
        if (d.purchaseDate.year == m.year && d.purchaseDate.month == m.month) {
          sum += d.price;
        }
      }
      monthData.add({'label': '${m.month}月', 'value': sum});
    }

    double maxVal = monthData.fold(
      0.0,
      (mx, e) => (e['value'] as double) > mx ? e['value'] as double : mx,
    );
    if (maxVal == 0) {
      maxVal = 1000;
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '¥${FormatUtils.formatCurrency(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= monthData.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthData[value.toInt()]['label'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(monthData.length, (index) {
            final val = monthData[index]['value'] as double;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: val,
                  gradient: const LinearGradient(
                    colors: [Colors.cyan, Colors.blueAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: Colors.blueAccent.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── Top Ranking ────────────────────────────────────────
  Widget _buildTopRanking(
    List<Device> devices,
    ThemeData theme, {
    required bool isByPrice,
  }) {
    if (devices.isEmpty) return const SizedBox();
    List<Device> sorted = List.from(devices);
    if (isByPrice) {
      sorted.sort((a, b) => b.price.compareTo(a.price));
    } else {
      sorted.sort((a, b) => b.dailyCost.compareTo(a.dailyCost));
    }
    final top5 = sorted.take(5).toList();
    final color = isByPrice ? _assetColor : _dailyColor;
    final isWarning = !isByPrice;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: List.generate(top5.length, (index) {
          final d = top5[index];
          final valstr = isByPrice
              ? '¥${FormatUtils.formatCurrency(d.price)}'
              : '¥${FormatUtils.formatCurrency(d.dailyCost)}/天';
          final key = '${isByPrice ? "p" : "c"}_$index';
          final isExpanded = _expandedRankingKey == key;

          return Column(
            children: [
              ListTile(
                onTap: () => setState(
                  () => _expandedRankingKey = isExpanded ? null : key,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Row(
                  children: [
                    if (isWarning) ...[
                      Icon(Icons.warning_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      d.category.value?.name ?? '未分类',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valstr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.hintColor,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.platform != null && d.platform!.isNotEmpty)
                        _buildDetailRow(
                          Icons.branding_watermark_outlined,
                          '平台',
                          d.platform!,
                          theme,
                        ),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        '购买日期',
                        FormatUtils.formatDate(d.purchaseDate),
                        theme,
                      ),
                      if (d.notes != null && d.notes!.isNotEmpty)
                        _buildDetailRow(
                          Icons.notes_rounded,
                          '备注',
                          d.notes!,
                          theme,
                        ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => context.push('/device/${d.id}'),
                        child: Text(
                          '查看完整详情 ⮕',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              if (index < top5.length - 1)
                Divider(
                  height: 1,
                  indent: 68,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: theme.hintColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enhanced Date Range Picker Widget ──────────────────
class _EnhancedDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange) onSelected;

  const _EnhancedDateRangePicker({
    required this.initialRange,
    required this.onSelected,
  });

  @override
  State<_EnhancedDateRangePicker> createState() =>
      _EnhancedDateRangePickerState();
}

class _EnhancedDateRangePickerState extends State<_EnhancedDateRangePicker> {
  late DateTime _start;
  late DateTime _end;
  bool _isSelectingStart = true;

  @override
  void initState() {
    super.initState();
    _start =
        widget.initialRange?.start ??
        DateTime.now().subtract(const Duration(days: 30));
    _end = widget.initialRange?.end ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '自定义统计周期',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('近7天', const Duration(days: 7)),
                _buildPresetChip('近30天', const Duration(days: 30)),
                _buildPresetChip('近90天', const Duration(days: 90)),
                _buildPresetChip('今年', null, isThisYear: true),
                _buildPresetChip('去年', null, isLastYear: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Start/End Selector
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  '起始日期',
                  _start,
                  _isSelectingStart,
                  () => setState(() => _isSelectingStart = true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: _buildDateButton(
                  '截止日期',
                  _end,
                  !_isSelectingStart,
                  () => setState(() => _isSelectingStart = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Year/Month Matrix
          Expanded(
            child: _DetailedDatePicker(
              initialDate: _isSelectingStart ? _start : _end,
              onChanged: (date) {
                setState(() {
                  if (_isSelectingStart) {
                    _start = date;
                    if (_start.isAfter(_end)) {
                      _end = _start.add(const Duration(days: 1));
                    }
                    _isSelectingStart = false; // Auto switch to end
                  } else {
                    _end = date;
                    if (_end.isBefore(_start)) {
                      _start = _end.subtract(const Duration(days: 1));
                    }
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              widget.onSelected(DateTimeRange(start: _start, end: _end));
              Navigator.pop(context);
            },
            child: const Text(
              '确定',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    Duration? duration, {
    bool isThisYear = false,
    bool isLastYear = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        padding: EdgeInsets.zero,
        onPressed: () {
          final now = DateTime.now();
          setState(() {
            if (isThisYear) {
              _start = DateTime(now.year, 1, 1);
              _end = now;
            } else if (isLastYear) {
              _start = DateTime(now.year - 1, 1, 1);
              _end = DateTime(now.year - 1, 12, 31);
            } else if (duration != null) {
              _end = now;
              _start = now.subtract(duration);
            }
          });
        },
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime date,
    bool active,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month}-${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  const _DetailedDatePicker({
    required this.initialDate,
    required this.onChanged,
  });

  @override
  State<_DetailedDatePicker> createState() => _DetailedDatePickerState();
}

class _DetailedDatePickerState extends State<_DetailedDatePicker> {
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    _viewDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Year/Month Selector Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1),
              ),
            ),
            DropdownButton<int>(
              value: _viewDate.year,
              items: List.generate(30, (i) => DateTime.now().year - i)
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
                  .toList(),
              onChanged: (y) =>
                  setState(() => _viewDate = DateTime(y!, _viewDate.month)),
              underline: const SizedBox(),
            ),
            DropdownButton<int>(
              value: _viewDate.month,
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
                  .toList(),
              onChanged: (m) =>
                  setState(() => _viewDate = DateTime(_viewDate.year, m!)),
              underline: const SizedBox(),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                () => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: DateTime(_viewDate.year, _viewDate.month + 1, 0).day,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(_viewDate.year, _viewDate.month, day);
              final isSelected =
                  date.year == widget.initialDate.year &&
                  date.month == widget.initialDate.month &&
                  date.day == widget.initialDate.day;
              return InkWell(
                onTap: () => widget.onChanged(date),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
