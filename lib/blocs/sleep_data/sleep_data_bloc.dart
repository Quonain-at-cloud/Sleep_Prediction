import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/sleep_data_service.dart';
import '../../services/cache_service.dart';
import '../../models/sleep_data_model.dart';
import '../../services/service_locator.dart';
import 'sleep_data_event.dart';
import 'sleep_data_state.dart';

class SleepDataBloc extends Bloc<SleepDataEvent, SleepDataState> {
  final SleepDataService _sleepDataService;
  final String _cacheKey = 'sleep_data_cache';

  SleepDataBloc({required SleepDataService sleepDataService})
      : _sleepDataService = sleepDataService,
        super(const SleepDataInitial()) {
    on<LoadSleepData>(_onLoadSleepData);
    on<AddSleepData>(_onAddSleepData);
    on<UpdateSleepData>(_onUpdateSleepData);
    on<DeleteSleepData>(_onDeleteSleepData);
  }

  Future<void> _onLoadSleepData(
    LoadSleepData event,
    Emitter<SleepDataState> emit,
  ) async {
    try {
      emit(const SleepDataLoading());
      
      String? userId = await serviceLocator.auth.getCurrentUserId();
      // If we have a date range, use it
      List<SleepDataModel> sleepRecords;
      if (event.startDate != null && event.endDate != null && userId != null) {
        sleepRecords = await _sleepDataService.getSleepDataForDateRange(
          userId,
          event.startDate!,
          event.endDate!,
        );
      } else {
        // Otherwise get all sleep data
        sleepRecords = await _sleepDataService.getSleepData();
      }
      
      emit(SleepDataLoaded(sleepRecords: sleepRecords));
    } catch (e) {
      emit(SleepDataError(e.toString()));
    }
  }

  Future<void> _onAddSleepData(
    AddSleepData event,
    Emitter<SleepDataState> emit,
  ) async {
    try {
      emit(const SleepDataLoading());
      
      // Create a new SleepDataModel
      final sleepData = SleepDataModel(
        id: '', // Will be assigned by backend
        userId: await serviceLocator.auth.getCurrentUserId() ?? '',
        date: event.sleepTime,
        bedTime: event.sleepTime,
        wakeUpTime: event.wakeTime,
        sleepDuration: event.wakeTime.difference(event.sleepTime).inMinutes,
        timeToFallAsleep: 15, // Default value
        interruptionCount: 0, // Default value
        interruptionTimes: [], // Default empty list
        sleepQuality: event.quality.toDouble(), // Convert int to double
        notes: event.notes,
        environmentalData: {}, // Default empty map
        dietaryData: {}, // Default empty map
      );
      
      await _sleepDataService.addSleepData(sleepData);

      emit(const SleepDataOperationSuccess('Sleep data added successfully'));
      
      // Refresh the data
      add(LoadSleepData(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      ));
    } catch (e) {
      emit(SleepDataError(e.toString()));
    }
  }

  Future<void> _onUpdateSleepData(
    UpdateSleepData event,
    Emitter<SleepDataState> emit,
  ) async {
    try {
      emit(const SleepDataLoading());
      
      // First get the existing sleep data
      final existingData = await _sleepDataService.getSleepDataById(event.id);
      
      if (existingData == null) {
        emit(const SleepDataError('Sleep data not found'));
        return;
      }
      
      // Create an updated model with the changes
      final updatedData = existingData.copyWith(
        bedTime: event.sleepTime ?? existingData.bedTime,
        wakeUpTime: event.wakeTime ?? existingData.wakeUpTime,
        sleepQuality: event.quality != null ? event.quality!.toDouble() : existingData.sleepQuality,
        notes: event.notes ?? existingData.notes,
        sleepDuration: event.wakeTime != null && event.sleepTime != null
            ? event.wakeTime!.difference(event.sleepTime!).inMinutes
            : existingData.sleepDuration,
      );

      await _sleepDataService.updateSleepData(updatedData);

      emit(const SleepDataOperationSuccess('Sleep data updated successfully'));
      
      // Refresh the data
      add(LoadSleepData(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      ));
    } catch (e) {
      emit(SleepDataError(e.toString()));
    }
  }

  Future<void> _onDeleteSleepData(
    DeleteSleepData event,
    Emitter<SleepDataState> emit,
  ) async {
    try {
      emit(const SleepDataLoading());
      
      await _sleepDataService.deleteSleepData(event.id);

      emit(const SleepDataOperationSuccess('Sleep data deleted successfully'));
      
      // Refresh the data
      add(LoadSleepData(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      ));
    } catch (e) {
      emit(SleepDataError(e.toString()));
    }
  }
}
