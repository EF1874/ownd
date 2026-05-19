import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../data/repositories/device_repository.dart';
import '../models/timeline_event.dart';
import '../../../shared/config/category_config.dart';

final timelineFilterProvider = StateProvider<Set<String>>((ref) => {});
final timelineTagFilterProvider = StateProvider<Set<String>>((ref) => {});

final timelineEventsProvider = StreamProvider<List<YearlyTimeline>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  final filterCategory = ref.watch(timelineFilterProvider);
  final filterTags = ref.watch(timelineTagFilterProvider);

  return repository.watchAllDevices().map((devices) {
    List<TimelineEvent> allEvents = [];

    // Flatten devices into events
    for (var device in devices) {
      // 1. Purchase Event
      allEvents.add(
        TimelineEvent(
          id: '${device.uuid}_purchase',
          deviceId: device.uuid,
          deviceName: device.name,
          customIconPath: device.customIconPath,
          categoryName: device.category.value?.name,
          date: device.purchaseDate,
          type: TimelineEventType.purchase,
          cost: device.price,
          note: 'Purchased',
          tags: device.tags,
        ),
      );

      // 2. Renewal History
      for (var i = 0; i < device.history.length; i++) {
        final history = device.history[i];
        final eventDate =
            history.recordDate ?? history.startDate ?? DateTime.now();

        allEvents.add(
          TimelineEvent(
            id: '${device.uuid}_renew_$i',
            deviceId: device.uuid,
            deviceName: device.name,
            customIconPath: device.customIconPath,
            categoryName: device.category.value?.name,
            date: eventDate,
            type: TimelineEventType.renewal,
            cost: history.price,
            note: history.note ?? 'Renewed',
            tags: device.tags,
          ),
        );
      }
    }

    // Filter events
    if (filterCategory.isNotEmpty) {
      allEvents = allEvents.where((e) {
        final major = CategoryConfig.getMajorCategory(e.categoryName);
        return filterCategory.contains(major);
      }).toList();
    }

    // Filter by Tags
    if (filterTags.isNotEmpty) {
      allEvents = allEvents.where((e) {
        return filterTags.every((tag) => e.tags.contains(tag));
      }).toList();
    }

    // Sort by Date Descending
    allEvents.sort((a, b) => b.date.compareTo(a.date));

    // Group by Year
    final years = groupBy(allEvents, (e) => e.date.year);
    final sortedYears = years.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedYears.map((year) {
      final yearEvents = years[year]!;
      final yearTotal = yearEvents.fold(0.0, (sum, e) => sum + e.cost);

      // Group by Month within Year
      final months = groupBy(yearEvents, (e) => e.date.month);
      final sortedMonths = months.keys.toList()..sort((a, b) => b.compareTo(a));

      final monthlyTimelines = sortedMonths.map((month) {
        final monthEvents = months[month]!;
        final monthTotal = monthEvents.fold(0.0, (sum, e) => sum + e.cost);
        return MonthlyTimeline(
          month: month,
          totalCost: monthTotal,
          events: monthEvents,
        );
      }).toList();

      return YearlyTimeline(
        year: year,
        totalCost: yearTotal,
        months: monthlyTimelines,
      );
    }).toList();
  });
});
