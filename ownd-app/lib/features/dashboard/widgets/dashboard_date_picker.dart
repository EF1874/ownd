part of '../dashboard_screen.dart';

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
