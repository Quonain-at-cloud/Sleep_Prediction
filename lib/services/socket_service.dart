import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class SocketService {
  late final io.Socket _socket;
  final LoggerService _logger = LoggerService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> init(String baseUrl) async {
    try {
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      _logger.i('SocketService: Initializing connection to $baseUrl');
      _logger.i('SocketService: Token available: ${token != null && token.isNotEmpty}');
      
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setReconnectionAttempts(5)
            .setAuth({'token': token}) // Include auth token
            .build(),
      );

      _socket.onConnect((_) {
        _isConnected = true;
        _logger.i('SocketService: Connected successfully');
      });
      
      _socket.onDisconnect((_) {
        _isConnected = false;
        _logger.w('SocketService: Disconnected');
      });
      
      _socket.onError((data) {
        _isConnected = false;
        _logger.e('SocketService: Error: $data');
      });

      _socket.onConnectError((data) {
        _isConnected = false;
        _logger.e('SocketService: Connection error: $data');
      });

      _socket.connect();
      
      // Wait a bit for connection
      await Future.delayed(const Duration(seconds: 2));
      
      if (_isConnected) {
        _logger.i('SocketService: Connection established successfully');
      } else {
        _logger.w('SocketService: Connection may not be established');
      }
    } catch (e) {
      _logger.e('SocketService: Failed to initialize', e);
    }
  }

  void on(String event, dynamic Function(dynamic) callback) {
    _logger.i('SocketService: Setting up listener for event: $event');
    _socket.on(event, (data) {
      _logger.i('SocketService: Received event $event with data: $data');
      callback(data);
    });
  }

  void dispose() {
    _logger.i('SocketService: Disposing socket connection');
    _socket.dispose();
  }
}
