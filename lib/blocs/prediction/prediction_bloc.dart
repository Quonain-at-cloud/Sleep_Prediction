import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/prediction_model.dart';
import '../../services/prediction_service.dart';
import '../../services/cache_service.dart';
import '../../services/service_locator.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final PredictionService _predictionService;

  PredictionBloc({required PredictionService predictionService})
      : _predictionService = predictionService,
        super(const PredictionInitial()) {
    on<GetSleepPrediction>(_onGetSleepPrediction);
    on<GetSleepRecommendations>(_onGetSleepRecommendations);
  }

  Future<void> _onGetSleepPrediction(
    GetSleepPrediction event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(const PredictionLoading());
      
      // Convert the factors to a parameters map
      final params = <String, dynamic>{
        'date': event.date.toIso8601String(),
      };
      
      // Add any additional factors to the parameters
      if (event.factors != null) {
        params.addAll(event.factors!);
      }
      
      // Get fresh prediction
      final prediction = await _predictionService.getPrediction(params);
      
      if (prediction != null) {
        emit(PredictionLoaded(prediction: prediction));
      } else {
        emit(const PredictionError('No prediction available for the selected date'));
      }
    } catch (e) {
      emit(PredictionError(e.toString()));
    }
  }

  Future<void> _onGetSleepRecommendations(
    GetSleepRecommendations event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(const PredictionLoading());

      // Create parameters maps for both API calls
      final params = <String, dynamic>{
        'date': event.date.toIso8601String(),
      };
      
      // Add sleep data to parameters if available
      if (event.currentSleepData != null) {
        params.addAll(event.currentSleepData!);
      }
      
      // Get recommendations first
      final recommendations = await _predictionService.getRecommendations(params);

      // Then get prediction using the same parameters
      final prediction = await _predictionService.getPrediction(params);
      
      if (prediction != null) {
        emit(PredictionLoaded(
          prediction: prediction,
          recommendations: recommendations,
        ));
      } else {
        // Even if we don't have a prediction, we might still have recommendations
        emit(PredictionLoaded(
          prediction: PredictionModel.simple(
            userId: await serviceLocator.auth.getCurrentUserId() ?? '',
            date: event.date,
            sleepQuality: 0,
            sleepDuration: 0,
            recommendations: recommendations,
          ),
          recommendations: recommendations,
        ));
      }
    } catch (e) {
      emit(PredictionError(e.toString()));
    }
  }
}
