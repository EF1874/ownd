// ignore_for_file: invalid_use_of_protected_member

part of '../dashboard_screen.dart';

extension _DashboardOverview on _DashboardContentState {
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
                _DashboardContentState._assetColor,
                Icons.account_balance_wallet_rounded,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRichStatCard(
                '实物保管件数',
                '$count 件',
                _DashboardContentState._countColor,
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
                _DashboardContentState._monthlyColor,
                Icons.calendar_month_rounded,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRichStatCard(
                '推演折损日耗',
                '¥${FormatUtils.formatCurrency(dailyCost)}',
                _DashboardContentState._dailyColor,
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
}
