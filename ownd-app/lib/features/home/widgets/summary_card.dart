import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/utils/format_utils.dart';

class SummaryCard extends StatelessWidget {
  final List<Device> filteredDevices;
  final List<Device> allDevices;
  final String? categoryName;

  const SummaryCard({
    super.key,
    required this.filteredDevices,
    required this.allDevices,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Requirements:
    // 1. If filtered list is empty (e.g. category has no items), show ALL items stats.
    // 2. Title changes based on filter (e.g., "Digital Assets" or "Total Assets").
    // 3. Status label changes (Expired for Subs, Retired for Physical).
    // 4. Value shows single sum (not split).

    // If filtered list is empty AND no category is selected, show ALL items stats.
    // If a category IS selected, show 0 stats for that category.
    final bool useAll = filteredDevices.isEmpty && categoryName == null;
    final List<Device> targetDevices = useAll ? allDevices : filteredDevices;

    final String? displayCategory = useAll ? null : categoryName;

    double totalValue = 0;
    double dailyCost = 0;
    int scrapCount = 0;

    final now = DateTime.now();

    for (var d in targetDevices) {
      totalValue += d.price;
      dailyCost += d.dailyCost;

      bool isScrapOrExpired = false;
      if (d.status == 'scrap') {
        isScrapOrExpired = true;
      } else {
        if (CategoryConfig.getMajorCategory(d.category.value?.name) == '虚拟订阅') {
          if (!d.isAutoRenew &&
              d.nextBillingDate != null &&
              d.nextBillingDate!.isBefore(now)) {
            isScrapOrExpired = true;
          }
        }
      }
      if (isScrapOrExpired) scrapCount++;
    }

    // Determine Title
    String title = '总资产';
    if (displayCategory != null && displayCategory != '全部') {
      title = '$displayCategory资产';
    }

    // Determine Scrap Label
    String scrapLabel = '已退役/已到期';
    final majorCat = CategoryConfig.getMajorCategory(displayCategory);
    if (majorCat == '虚拟订阅') {
      scrapLabel = '已到期';
    } else {
      // Assume physical for others
      scrapLabel = '已退役';
    }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Icon(
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
                          '¥${FormatUtils.formatCurrency(totalValue)}',
                          textColor: textColor,
                        ),
                        _buildStatItem(
                          context,
                          '预估日耗',
                          '¥${FormatUtils.formatCurrency(dailyCost)}',
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
                        _buildBottomInfo(
                          '总数汇总',
                          targetDevices.length.toString(),
                          textColor: textColor,
                        ),
                        _buildBottomInfo(
                          scrapLabel,
                          scrapCount.toString(),
                          textColor: textColor,
                        ),
                      ],
                    ),
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
