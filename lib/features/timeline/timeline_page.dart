import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logic/timeline_provider.dart';
import 'models/timeline_event.dart';
import 'widgets/timeline_node.dart';
import '../../shared/utils/format_utils.dart';
import '../home/widgets/multi_select_filter_delegate.dart';
import '../home/home_screen.dart'; // for deviceListProvider

/// Embeddable content for use inside TabBarView (no Scaffold/AppBar)
class TimelineContent extends ConsumerStatefulWidget {
  const TimelineContent({super.key});

  @override
  ConsumerState<TimelineContent> createState() => _TimelineContentState();
}

class _TimelineContentState extends ConsumerState<TimelineContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildTimelineBody(context, ref, embedded: true);
  }
}

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: _buildTimelineBody(context, ref, embedded: false));
  }
}

Widget _buildTimelineBody(
  BuildContext context,
  WidgetRef ref, {
  required bool embedded,
}) {
  final timelineAsync = ref.watch(timelineEventsProvider);
  final selectedFilter = ref.watch(timelineFilterProvider);
  final selectedTags = ref.watch(timelineTagFilterProvider);
  final devicesAsync = ref.watch(deviceListProvider);
  final theme = Theme.of(context);

  // Color definitions for lines
  final yearLineColor = theme.colorScheme.primary.withValues(alpha: 0.5);
  final monthLineColor = theme.colorScheme.secondary.withValues(alpha: 0.5);
  final dayLineColor = theme.colorScheme.tertiary.withValues(alpha: 0.3);

  return CustomScrollView(
    slivers: [
      if (!embedded) ...[
        SliverAppBar(
          pinned: true,
          leading: const BackButton(),
          title: Text(
            '物历',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 44,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: theme.scaffoldBackgroundColor,
        ),
      ],

      SliverPersistentHeader(
        pinned: true,
        delegate: MultiSelectFilterDelegate(
          selectedCategories: selectedFilter,
          onSelectionChanged: (categories) {
            ref.read(timelineFilterProvider.notifier).state = categories;
          },
        ),
      ),

      if (devicesAsync.valueOrNull != null &&
          devicesAsync.valueOrNull!.any((d) => d.tags.isNotEmpty))
        SliverToBoxAdapter(
          child: Container(
            height: 48,
            color: theme.scaffoldBackgroundColor,
            alignment: Alignment.centerLeft,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final tag
                    in (devicesAsync.valueOrNull!
                        .expand((d) => d.tags)
                        .toSet()
                        .toList()
                      ..sort()))
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: FilterChip(
                      label: Text('#$tag'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: selectedTags.contains(tag)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      selected: selectedTags.contains(tag),
                      onSelected: (selected) {
                        final newTags = Set<String>.from(selectedTags);
                        if (selected) {
                          newTags.add(tag);
                        } else {
                          newTags.remove(tag);
                        }
                        ref.read(timelineTagFilterProvider.notifier).state =
                            newTags;
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

      timelineAsync.when(
        data: (timelineYears) {
          if (timelineYears.isEmpty) {
            return const SliverFillRemaining(
              child: Center(
                child: Text('暂无记录', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final yearData = timelineYears[index];

              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: yearLineColor, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Year Header
                      _buildYearHeader(
                        context,
                        yearData.year,
                        yearData.totalCost,
                      ),

                      // Months
                      ...yearData.months.map((monthData) {
                        // Pre-group day events
                        final eventsByDay = <int, List<TimelineEvent>>{};
                        for (var e in monthData.events) {
                          eventsByDay.putIfAbsent(e.date.day, () => []).add(e);
                        }
                        final sortedDays = eventsByDay.keys.toList()
                          ..sort((a, b) => b.compareTo(a));

                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: monthLineColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Header
                                _buildMonthHeader(context, monthData),

                                // Days
                                ...sortedDays.map((day) {
                                  final dayEvents = eventsByDay[day]!;
                                  final dayTotal = dayEvents.fold(
                                    0.0,
                                    (sum, e) => sum + e.cost,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: dayLineColor,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDayHeader(
                                            context,
                                            monthData.month,
                                            day,
                                            dayTotal,
                                          ),

                                          ...dayEvents.map(
                                            (event) =>
                                                TimelineNode(event: event),
                                          ),

                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }, childCount: timelineYears.length),
          );
        },
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) =>
            SliverFillRemaining(child: Center(child: Text('Error: $err'))),
      ),
    ],
  );
}

Widget _buildYearHeader(BuildContext context, int year, double totalCost) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$year',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text('年', style: theme.textTheme.titleSmall),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            '¥${FormatUtils.formatCurrency(totalCost)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMonthHeader(BuildContext context, MonthlyTimeline monthData) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${monthData.month}月',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            '¥${FormatUtils.formatCurrency(monthData.totalCost)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDayHeader(
  BuildContext context,
  int month,
  int day,
  double totalCost,
) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$month月$day日',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.tertiary,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            '¥${FormatUtils.formatCurrency(totalCost)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
