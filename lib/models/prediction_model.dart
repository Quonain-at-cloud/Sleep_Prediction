import 'package:intl/intl.dart';

class PredictionModel {
  final String id;
  final String userId;
  final DateTime date;
  final double predictionScore; // 0-1 scale, higher means more likely to have interruptions
  final int predictedInterruptionCount;
  final List<Map<String, dynamic>> predictedInterruptionWindows; // [{startTime: DateTime, endTime: DateTime, probability: double}]
  final Map<String, double> contributingFactors; // {factor: weight}
  final List<String> recommendations;
  final Map<String, dynamic> inputData; // The data used to generate the prediction
  final DateTime createdAt;
  
  // Sleep quality and duration for simple predictions
  final int? sleepQuality;
  final int? sleepDuration;

  PredictionModel({
    required this.id,
    required this.userId,
    required this.date,
    this.predictionScore = 0.0,
    this.predictedInterruptionCount = 0,
    this.predictedInterruptionWindows = const [],
    this.contributingFactors = const {},
    this.recommendations = const [],
    this.inputData = const {},
    DateTime? createdAt,
    this.sleepQuality,
    this.sleepDuration,
  }) : this.createdAt = createdAt ?? DateTime.now();
  
  // Simplified constructor for basic predictions
  factory PredictionModel.simple({
    required String userId,
    required DateTime date,
    required int sleepQuality,
    required int sleepDuration,
    List<String> recommendations = const [],
  }) {
    return PredictionModel(
      id: '',
      userId: userId,
      date: date,
      sleepQuality: sleepQuality,
      sleepDuration: sleepDuration,
      recommendations: recommendations,
    );
  }

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    // Handle recommendations: it can be a single string or a list of strings
    List<String> recommendationsList = [];
    if (json['recommendations'] != null) {
      if (json['recommendations'] is String) {
        recommendationsList = (json['recommendations'] as String)
            .split('•')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (json['recommendations'] is List) {
        recommendationsList = List<String>.from(json['recommendations']);
      }
    }

    // Handle interruption windows which might just be time strings
    List<Map<String, dynamic>> windows = [];
    if (json['predictedInterruptionWindows'] != null) {
      for (var window in (json['predictedInterruptionWindows'] as List)) {
        final windowMap = window as Map<String, dynamic>;
        // The backend now sends simple time strings, not full DateTimes
        windows.add({
          'startTime': windowMap['startTime'], // Keep as String
          'endTime': windowMap['endTime'],     // Keep as String
          'probability': windowMap['probability'],
        });
      }
    }
    
    return PredictionModel(
      id: json['_id'] ?? json['id'] ?? '', // Handle MongoDB's _id
      userId: json['userId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      predictionScore: (json['predictionScore'] ?? 0.0).toDouble(),
      predictedInterruptionCount: json['predictedInterruptionCount'] ?? 0,
      predictedInterruptionWindows: windows,
      contributingFactors: Map<String, double>.from(json['contributingFactors'] ?? {}),
      recommendations: recommendationsList,
      inputData: json['inputData'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      // Adding new fields from the Node.js service response
      sleepQuality: (json['normalizedScore'] != null) ? ((json['normalizedScore'] * 10).round()) : null,
      sleepDuration: json['sleepDuration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    // No need to parse/format time strings back to DateTime for JSON serialization
    final result = <String, dynamic>{
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'predictionScore': predictionScore,
      'predictedInterruptionCount': predictedInterruptionCount,
      'predictedInterruptionWindows': predictedInterruptionWindows, // Already in the correct Map<String, dynamic> format
      'contributingFactors': contributingFactors,
      'recommendations': recommendations,
      'inputData': inputData,
      'createdAt': createdAt.toIso8601String(),
    };
    
    // Add optional fields if they're not null
    if (sleepQuality != null) result['sleepQuality'] = sleepQuality!;
    if (sleepDuration != null) result['sleepDuration'] = sleepDuration!;
    
    return result;
  }

  PredictionModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? predictionScore,
    int? predictedInterruptionCount,
    List<Map<String, dynamic>>? predictedInterruptionWindows,
    Map<String, double>? contributingFactors,
    List<String>? recommendations,
    Map<String, dynamic>? inputData,
    DateTime? createdAt,
    int? sleepQuality,
    int? sleepDuration,
  }) {
    return PredictionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      predictionScore: predictionScore ?? this.predictionScore,
      predictedInterruptionCount: predictedInterruptionCount ?? this.predictedInterruptionCount,
      predictedInterruptionWindows: predictedInterruptionWindows ?? this.predictedInterruptionWindows,
      contributingFactors: contributingFactors ?? this.contributingFactors,
      recommendations: recommendations ?? this.recommendations,
      inputData: inputData ?? this.inputData,
      createdAt: createdAt ?? this.createdAt,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepDuration: sleepDuration ?? this.sleepDuration,
    );
  }
} 