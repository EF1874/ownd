// ignore_for_file: invalid_use_of_protected_member

part of '../dashboard_screen.dart';

extension _DashboardTrends on _DashboardContentState {
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
    final color = isByPrice
        ? _DashboardContentState._assetColor
        : _DashboardContentState._dailyColor;
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
