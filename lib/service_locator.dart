import 'package:get_it/get_it.dart';
import 'services/socket_service.dart';
import 'providers/notification_provider.dart';

final serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // existing registrations ...

  // Socket service (singleton)
  serviceLocator.registerLazySingleton<SocketService>(() => SocketService());

  // Notification Provider
  serviceLocator.registerLazySingleton<NotificationProvider>(() => NotificationProvider(socketService: serviceLocator<SocketService>()));
}
