import 'dart:io';
import 'package:flutter/material.dart';
import '../models/timeline_event.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/config/category_config.dart';

class TimelineNode extends StatelessWidget {
  final TimelineEvent event;

  const TimelineNode({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Icon Logic
    late Widget iconWidget;
    if (event.customIconPath != null &&
        File(event.customIconPath!).existsSync()) {
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(event.customIconPath!),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Fallback to Category Icon
      final catItem = CategoryConfig.getItem(event.categoryName);
      final iconData = IconUtils.getIconData(catItem.iconPath);
      iconWidget = Icon(
        iconData,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.deviceName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(event.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeName(event.type),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getTypeColor(event.type),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-¥${FormatUtils.formatCurrency(event.cost)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.note != null && event.note?.isNotEmpty == true)
                  Text(
                    event.note ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.purchase:
        return Colors.blue;
      case TimelineEventType.renewal:
        return Colors.green;
      case TimelineEventType.maintenance:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeName(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.purchase:
        return '购入';
      case TimelineEventType.renewal:
        return '续费';
      case TimelineEventType.maintenance:
        return '维护';
      default:
        return '其他';
    }
  }
}
