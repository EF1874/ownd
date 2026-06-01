enum TimelineEventType { purchase, renewal, maintenance, other }

class TimelineEvent {
  final String id;
  final String deviceId;
  final String deviceName;
  final String? customIconPath;
  final String? categoryName;
  final String? majorCategoryName;
  final DateTime date;
  final TimelineEventType type;
  final double cost;
  final String? note;
  final List<String> tags;

  TimelineEvent({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    this.customIconPath,
    this.categoryName,
    this.majorCategoryName,
    required this.date,
    required this.type,
    required this.cost,
    this.note,
    this.tags = const [],
  });
}

class MonthlyTimeline {
  final int month;
  final double totalCost;
  final List<TimelineEvent> events;

  MonthlyTimeline({
    required this.month,
    required this.totalCost,
    required this.events,
  });
}

class YearlyTimeline {
  final int year;
  final double totalCost;
  final List<MonthlyTimeline> months;

  YearlyTimeline({
    required this.year,
    required this.totalCost,
    required this.months,
  });
}
