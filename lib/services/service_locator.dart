import 'package:get_it/get_it.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/sleep_data/sleep_data_bloc.dart';
import '../blocs/prediction/prediction_bloc.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'error_service.dart';
import 'sleep_data_service.dart';
import 'prediction_service.dart';
import 'logger_service.dart';
import 'image_service.dart';
import 'socket_service.dart';
import 'schedule_service.dart';
import '../providers/schedule_provider.dart';
import '../providers/notification_provider.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Logger
  serviceLocator.registerSingleton<LoggerService>(LoggerService());
  
  // Core Services
  serviceLocator.registerSingleton<CacheService>(CacheService());
  serviceLocator.registerSingleton<ConnectivityService>(ConnectivityService());
  
  // Initialize services that require async initialization
  await serviceLocator<CacheService>().initialize();
  
  // API and Error Services
  // API Service (requires async initialization)
  final apiService = ApiService();
  await apiService.init(); // Await the initialization
  serviceLocator.registerSingleton<ApiService>(apiService);
  serviceLocator.registerSingleton<ErrorService>(ErrorService());
  
  // Auth Service (requires async initialization)
  final authService = AuthService(apiService: serviceLocator<ApiService>());
  await authService.init(); // Await the initialization
  serviceLocator.registerSingleton<AuthService>(authService);

  // Sleep and Prediction Services
  serviceLocator.registerSingleton<SleepDataService>(SleepDataService(
    apiService: serviceLocator<ApiService>(),
  ));
  serviceLocator.registerSingleton<PredictionService>(PredictionService());
  
  // Socket & Notification Services
  serviceLocator.registerLazySingleton<SocketService>(() => SocketService());
  serviceLocator.registerLazySingleton<NotificationProvider>(() => NotificationProvider(
    socketService: serviceLocator<SocketService>(),
    authService: serviceLocator<AuthService>(),
  ));

  // Schedule Service & Provider
  serviceLocator.registerSingleton<ScheduleService>(ScheduleService(apiService: serviceLocator<ApiService>()));
  serviceLocator.registerLazySingleton<ScheduleProvider>(() => ScheduleProvider(scheduleService: serviceLocator<ScheduleService>(), authService: serviceLocator<AuthService>()));

  // Image Service
  serviceLocator.registerSingleton<ImageService>(ImageService());

  // BLoCs
  serviceLocator.registerFactory<AuthBloc>(() => AuthBloc(
    authService: serviceLocator<AuthService>(),
  ));
  serviceLocator.registerFactory<SleepDataBloc>(() => SleepDataBloc(
    sleepDataService: serviceLocator<SleepDataService>(),
  ));
  serviceLocator.registerFactory<PredictionBloc>(() => PredictionBloc(
    predictionService: serviceLocator<PredictionService>(),
  ));
}

Future<void> resetServiceLocator() async {
  // Dispose services that need cleanup
  final authService = serviceLocator<AuthService>();
  authService.dispose();
  
  // Reset GetIt instance
  await serviceLocator.reset();
}

// Extension method for easier access to services
extension ServiceLocatorExtension on GetIt {
  LoggerService get logger => get<LoggerService>();
  CacheService get cache => get<CacheService>();
  ConnectivityService get connectivity => get<ConnectivityService>();
  ErrorService get error => get<ErrorService>();
  ApiService get api => get<ApiService>();
  AuthService get auth => get<AuthService>();
  SleepDataService get sleepData => get<SleepDataService>();
  PredictionService get prediction => get<PredictionService>();
  ScheduleService get schedule => get<ScheduleService>();
  ScheduleProvider get scheduleProvider => get<ScheduleProvider>();
  ImageService get image => get<ImageService>();
  AuthBloc get authBloc => get<AuthBloc>();
  SleepDataBloc get sleepDataBloc => get<SleepDataBloc>();
  PredictionBloc get predictionBloc => get<PredictionBloc>();
}
