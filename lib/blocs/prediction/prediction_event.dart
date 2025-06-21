import 'package:equatable/equatable.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

class GetSleepPrediction extends PredictionEvent {
  final DateTime date;
  final Map<String, dynamic> factors;

  const GetSleepPrediction({
    required this.date,
    required this.factors,
  });

  @override
  List<Object?> get props => [date, factors];
}

class GetSleepRecommendations extends PredictionEvent {
  final DateTime date;
  final Map<String, dynamic> currentSleepData;

  const GetSleepRecommendations({
    required this.date,
    required this.currentSleepData,
  });

  @override
  List<Object?> get props => [date, currentSleepData];
}
