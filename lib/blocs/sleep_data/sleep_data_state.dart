import 'package:equatable/equatable.dart';
import '../../models/sleep_data_model.dart';

abstract class SleepDataState extends Equatable {
  const SleepDataState();

  @override
  List<Object?> get props => [];
}

class SleepDataInitial extends SleepDataState {
  const SleepDataInitial();
}

class SleepDataLoading extends SleepDataState {
  const SleepDataLoading();
}

class SleepDataLoaded extends SleepDataState {
  final List<SleepDataModel> sleepRecords;

  const SleepDataLoaded({required this.sleepRecords});

  @override
  List<Object?> get props => [sleepRecords];
}

class SleepDataOperationSuccess extends SleepDataState {
  final String message;

  const SleepDataOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SleepDataError extends SleepDataState {
  final String message;

  const SleepDataError(this.message);

  @override
  List<Object?> get props => [message];
}
