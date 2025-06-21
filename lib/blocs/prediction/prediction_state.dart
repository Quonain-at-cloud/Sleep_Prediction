import 'package:equatable/equatable.dart';
import '../../models/prediction_model.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

class PredictionInitial extends PredictionState {
  const PredictionInitial();
}

class PredictionLoading extends PredictionState {
  const PredictionLoading();
}

class PredictionLoaded extends PredictionState {
  final PredictionModel prediction;
  final List<String>? recommendations;

  const PredictionLoaded({
    required this.prediction,
    this.recommendations,
  });

  @override
  List<Object?> get props => [prediction, recommendations];
}

class PredictionError extends PredictionState {
  final String message;

  const PredictionError(this.message);

  @override
  List<Object?> get props => [message];
}
