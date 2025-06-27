import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 18)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String userId;

  @HiveField(4)
  final String? type; // created, updated, deleted, completed, missed, reminder

  @HiveField(5)
  final String? category; // lunch, sleepStart, etc.

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.userId,
    this.type,
    this.category,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      userId: json['userId'] ?? '',
      type: json['type'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
      };
}
