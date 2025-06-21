// Base API Exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

// Validation related exceptions
class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}

// Authentication related exceptions
class AuthException extends ApiException {
  AuthException(String message) : super(message);
}

// Resource conflict exceptions
class ConflictException extends ApiException {
  ConflictException(String message) : super(message);
}

// Resource not found exceptions
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

// Server related exceptions
class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

// Network related exceptions
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

// Timeout related exceptions
class TimeoutException extends ApiException {
  TimeoutException(String message) : super(message);
}
