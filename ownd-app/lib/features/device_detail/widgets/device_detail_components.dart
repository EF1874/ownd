part of '../device_detail_screen.dart';

class _HeaderImageButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double bottom;

  const _HeaderImageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.bottom = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: bottom,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

enum _SubscriptionPeriodStatus { active, upcoming, ended, unknown }

class _SubscriptionPeriod {
  final int index;
  final SubscriptionHistory history;
  final _SubscriptionPeriodStatus status;
  final bool canEdit;

  const _SubscriptionPeriod({
    required this.index,
    required this.history,
    required this.status,
    required this.canEdit,
  });
}

class _SubscriptionPeriodTile extends StatelessWidget {
  final _SubscriptionPeriod period;
  final DateFormat dateFormat;
  final ThemeData theme;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SubscriptionPeriodTile({
    required this.period,
    required this.dateFormat,
    required this.theme,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final history = period.history;
    final statusStyle = _statusStyle(context, period.status);
    final durationDays = history.startDate != null && history.endDate != null
        ? SubscriptionUtils.dateOnly(history.endDate!)
                  .difference(SubscriptionUtils.dateOnly(history.startDate!))
                  .inDays +
              1
        : null;
    final isAutoRenewal = _isAutoRenewalHistory(history);
    final displayNote = _displayNote(history);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusStyle.border,
          width: statusStyle.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: _InlineNumberText(
                        prefix: '第',
                        number: '${period.index}',
                        suffix: '期',
                        color: theme.colorScheme.onSurface,
                        numberStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: _statusLabel(period.status),
                      color: statusStyle.accent,
                    ),
                  ],
                ),
              ),
              _InlineNumberText(
                prefix: '¥',
                number: FormatUtils.formatCurrency(history.price),
                color: theme.colorScheme.error,
                numberStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<_HistoryAction>(
                  tooltip: '记录操作',
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    switch (action) {
                      case _HistoryAction.edit:
                        onEdit?.call();
                        break;
                      case _HistoryAction.delete:
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _HistoryAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('编辑记录'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '删除记录',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _PeriodInfoRow(label: '开始日期', value: _formatDate(history.startDate)),
          const SizedBox(height: 6),
          _PeriodInfoRow(label: '到期日期', value: _formatDate(history.endDate)),
          const SizedBox(height: 6),
          _PeriodModeRow(
            value:
                '${SubscriptionUtils.cycleLabel(history.cycleType)} · ${SubscriptionUtils.calculationModeLabel(history.cycleCalculationMode, cycleDays: history.cycleDays)}${durationDays == null ? '' : ' · $durationDays天'}',
            showAutoRenewBadge: isAutoRenewal,
          ),
          if (displayNote != null) ...[
            const SizedBox(height: 6),
            _PeriodInfoRow(label: '备注', value: displayNote),
          ],
        ],
      ),
    );
  }

  bool _isAutoRenewalHistory(SubscriptionHistory history) {
    if (history.isAutoRenew) return true;
    return history.note?.trim().startsWith('自动续费') ?? false;
  }

  String? _displayNote(SubscriptionHistory history) {
    final note = history.note?.trim();
    if (note == null || note.isEmpty) return null;
    return note.startsWith('自动续费') ? null : note;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未记录';
    return dateFormat.format(date);
  }

  String _statusLabel(_SubscriptionPeriodStatus status) {
    return switch (status) {
      _SubscriptionPeriodStatus.active => '当前',
      _SubscriptionPeriodStatus.upcoming => '未开始',
      _SubscriptionPeriodStatus.ended => '已结束',
      _SubscriptionPeriodStatus.unknown => '记录',
    };
  }

  _PeriodStatusStyle _statusStyle(
    BuildContext context,
    _SubscriptionPeriodStatus status,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      _SubscriptionPeriodStatus.active => _PeriodStatusStyle(
        accent: colorScheme.primary,
        background: colorScheme.primary.withValues(alpha: 0.10),
        border: colorScheme.primary.withValues(alpha: 0.72),
        borderWidth: 1.6,
      ),
      _SubscriptionPeriodStatus.upcoming => _PeriodStatusStyle(
        accent: Colors.teal.shade700,
        background: Colors.teal.withValues(alpha: 0.08),
        border: Colors.teal.withValues(alpha: 0.48),
        borderWidth: 1.2,
      ),
      _SubscriptionPeriodStatus.ended => _PeriodStatusStyle(
        accent: Colors.blueGrey.shade600,
        background: Colors.blueGrey.withValues(alpha: 0.055),
        border: Colors.blueGrey.withValues(alpha: 0.24),
        borderWidth: 1,
      ),
      _SubscriptionPeriodStatus.unknown => _PeriodStatusStyle(
        accent: AppColors.ash,
        background: theme.colorScheme.surface,
        border: theme.dividerColor.withValues(alpha: 0.6),
        borderWidth: 1,
      ),
    };
  }
}

enum _HistoryAction { edit, delete }

class _PeriodStatusStyle {
  final Color accent;
  final Color background;
  final Color border;
  final double borderWidth;

  const _PeriodStatusStyle({
    required this.accent,
    required this.background,
    required this.border,
    required this.borderWidth,
  });
}
