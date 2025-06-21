import 'package:intl/intl.dart';

class SleepDataModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeUpTime;
  final int sleepDuration; // in minutes
  final int timeToFallAsleep; // in minutes
  final int interruptionCount;
  final List<DateTime> interruptionTimes;
  final double sleepQuality; // 0-10 scale
  final String notes;
  final Map<String, dynamic> environmentalData; // noise, light, temperature
  final Map<String, dynamic> dietaryData; // caffeine, alcohol, meal times
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepDataModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.bedTime,
    required this.wakeUpTime,
    this.sleepDuration = 0,
    this.timeToFallAsleep = 0,
    this.interruptionCount = 0,
    this.interruptionTimes = const [],
    this.sleepQuality = 0.0,
    this.notes = '',
    this.environmentalData = const {},
    this.dietaryData = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  factory SleepDataModel.fromJson(Map<String, dynamic> json) {
    List<DateTime> interruptionTimes = [];
    if (json['interruptionTimes'] != null) {
      for (var timeStr in (json['interruptionTimes'] as List)) {
        interruptionTimes.add(DateTime.parse(timeStr));
      }
    }
    
    return SleepDataModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      bedTime: json['bedTime'] != null ? DateTime.parse(json['bedTime']) : DateTime.now(),
      wakeUpTime: json['wakeUpTime'] != null ? DateTime.parse(json['wakeUpTime']) : DateTime.now().add(const Duration(hours: 8)),
      sleepDuration: json['sleepDuration'] ?? 0,
      timeToFallAsleep: json['timeToFallAsleep'] ?? 0,
      interruptionCount: json['interruptionCount'] ?? 0,
      interruptionTimes: interruptionTimes,
      sleepQuality: (json['sleepQuality'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      environmentalData: json['environmentalData'] ?? {},
      dietaryData: json['dietaryData'] ?? {},
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'bedTime': bedTime.toIso8601String(),
      'wakeUpTime': wakeUpTime.toIso8601String(),
      'sleepDuration': sleepDuration,
      'timeToFallAsleep': timeToFallAsleep,
      'interruptionCount': interruptionCount,
      'interruptionTimes': interruptionTimes.map((time) => time.toIso8601String()).toList(),
      'sleepQuality': sleepQuality,
      'notes': notes,
      'environmentalData': environmentalData,
      'dietaryData': dietaryData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SleepDataModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? bedTime,
    DateTime? wakeUpTime,
    int? sleepDuration,
    int? timeToFallAsleep,
    int? interruptionCount,
    List<DateTime>? interruptionTimes,
    double? sleepQuality,
    String? notes,
    Map<String, dynamic>? environmentalData,
    Map<String, dynamic>? dietaryData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bedTime: bedTime ?? this.bedTime,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      timeToFallAsleep: timeToFallAsleep ?? this.timeToFallAsleep,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      interruptionTimes: interruptionTimes ?? this.interruptionTimes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      notes: notes ?? this.notes,
      environmentalData: environmentalData ?? this.environmentalData,
      dietaryData: dietaryData ?? this.dietaryData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 