import 'package:hive/hive.dart';
part 'schedule_item.g.dart';

@HiveType(typeId: 19)
class ScheduleItem extends HiveObject {
  @HiveField(0)
  final String id; // backend _id

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime scheduledAt;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  final String color;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.category,
    required this.scheduledAt,
    this.completed = false,
    required this.color,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'other',
      scheduledAt: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      completed: json['completed'] ?? false,
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'category': category,
        'startTime': scheduledAt.toIso8601String(),
        'completed': completed,
        'color': color,
      };
}
