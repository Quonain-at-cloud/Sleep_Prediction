import 'package:equatable/equatable.dart';

abstract class SleepDataEvent extends Equatable {
  const SleepDataEvent();

  @override
  List<Object?> get props => [];
}

class LoadSleepData extends SleepDataEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadSleepData({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AddSleepData extends SleepDataEvent {
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int quality;
  final String notes;

  const AddSleepData({
    required this.sleepTime,
    required this.wakeTime,
    required this.quality,
    this.notes = '',
  });

  @override
  List<Object?> get props => [sleepTime, wakeTime, quality, notes];
}

class UpdateSleepData extends SleepDataEvent {
  final String id;
  final DateTime? sleepTime;
  final DateTime? wakeTime;
  final int? quality;
  final String? notes;

  const UpdateSleepData({
    required this.id,
    this.sleepTime,
    this.wakeTime,
    this.quality,
    this.notes,
  });

  @override
  List<Object?> get props => [id, sleepTime, wakeTime, quality, notes];
}

class DeleteSleepData extends SleepDataEvent {
  final String id;

  const DeleteSleepData({required this.id});

  @override
  List<Object?> get props => [id];
}
