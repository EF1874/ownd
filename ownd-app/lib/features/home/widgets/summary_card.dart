import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/format_utils.dart';
import '../home_devices_provider.dart';

class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final stats = summary.valueOrNull;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color brandColor = Color.fromARGB(
      255,
      100,
      135,
      212,
    ); // User requested Soft Lavender-Blue
    const Color textColor = Colors.white; // High contrast on this color

    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: brandColor.withValues(
              alpha: isDark ? 0.8 : 0.9,
            ), // Increased opacity to reduce glass feel
            boxShadow: [
              BoxShadow(
                color: brandColor.withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 3,
                sigmaY: 3,
              ), // Reduced blur as requested
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '总资产',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.insights_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatItem(
                          context,
                          '资产估值',
                          stats == null
                              ? '--'
                              : '¥${FormatUtils.formatCurrency(stats.totalValue)}',
                          textColor: textColor,
                        ),
                        _buildStatItem(
                          context,
                          '预估日耗',
                          stats == null
                              ? '--'
                              : '¥${FormatUtils.formatCurrency(stats.dailyCost)}',
                          crossAxisAlignment: CrossAxisAlignment.end,
                          textColor: textColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildBottomInfo(
                            '总数',
                            stats?.itemCount.toString() ?? '--',
                            textColor: textColor,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildBottomInfo(
                              '退役/到期',
                              stats?.scrapOrExpiredCount.toString() ?? '--',
                              textColor: textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildBottomInfo(
                              '即将到期',
                              stats?.expiringSoonCount.toString() ?? '--',
                              textColor: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (summary.hasError && stats == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '概览加载失败，请下拉刷新',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.98, 0.98),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(
    String label,
    String value, {
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
