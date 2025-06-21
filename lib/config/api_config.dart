class ApiConfig {
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api';
  
  // For physical device on same network as development machine
  // Update this to the IP of the machine running the backend that is reachable from your phone.
  // Set this to your PC's current IP address (from ipconfig) when connected to your phone's hotspot.
  // Example: 'http://192.168.43.123:3000/api'
  static const String deviceBaseUrl = 'http://192.168.100.10:3000/api';
  
  // For local development (when testing on the same machine)
  static const String localhostUrl = 'http://localhost:3000/api';
  
  // Production URL - Virtual Machine deployment
  static const String prodBaseUrl = 'http://20.2.139.176:3000/api';
  
  // CONFIGURATION OPTIONS - Update these as needed
  // IMPORTANT: Set isPhysicalDevice to true when testing on a physical device
  static const bool isPhysicalDevice = true;   // Set to false for local dev on emulator/desktop
  static const bool isDevelopment = true;      // Set to true for local development
  static const bool useLocalhost = false;       // Use localhost for all API calls
  
  // Get the base URL based on environment and device type
  static String get baseUrl {
    if (!isDevelopment) {
      return prodBaseUrl;
    } else if (useLocalhost) {
      return localhostUrl;  // For testing on the same machine
    } else {
      return isPhysicalDevice ? deviceBaseUrl : emulatorBaseUrl;
    }
  }
  
  // API endpoints
  static final endpoints = _ApiEndpoints();
}

class _ApiEndpoints {
  // Auth endpoints
  final auth = _AuthEndpoints();
  
  // Sleep data endpoints
  final sleepData = _SleepDataEndpoints();
  
  // Prediction endpoints
  final predictions = _PredictionEndpoints();
  
  // User endpoints
  final users = _UserEndpoints();

  // Schedule endpoints
  final schedule = _ScheduleEndpoints();
}

class _AuthEndpoints {
  final String login = '/users/login';
  final String register = '/users/register';
  final String forgotPassword = '/users/forgot-password';
  final String verifyOTP = '/users/verify-otp';
  final String resetPassword = '/users/reset-password';
  final String refreshToken = '/users/refresh-token';
}

class _SleepDataEndpoints {
  final String base = '/sleep-data';
  final String submit = '/sleep-data/submit-data'; // Added submit endpoint
  String byId(String id) => '$base/$id';
  final String latest = '/sleep-data/latest';
  String byUser(String userId) => '$base/user/$userId';
  String byDateRange(DateTime start, DateTime end) => 
      '$base?startDate=${start.toIso8601String()}&endDate=${end.toIso8601String()}';
}

class _PredictionEndpoints {
  final String base = '/predictions';
  String byId(String id) => '$base/$id';
  final String generate = '/predictions/generate';
  final String latest = '/predictions/latest';
  final String predict = '/predictions/predict'; // This is the old direct ML call endpoint
  final String getLatestWithRecommendations = '/predictions/prediction'; // New endpoint for fetching latest prediction and recs
  final String recommendations = '/predictions/recommendations';
  String byUser(String userId) => '$base/user/$userId';
  String byDateRange(DateTime start, DateTime end) => 
      '$base/history?startDate=${start.toIso8601String()}&endDate=${end.toIso8601String()}';
}

class _ScheduleEndpoints {
  final String base = '/schedule';
  String byUser(String userId) => '$base/$userId';
}

class _UserEndpoints {
  final String base = '/users';
  final String profile = '/users/profile';
  String byId(String id) => '$base/$id';
  final String updateProfile = '/users/profile';
  final String uploadProfileImage = '/users/profile/image';
  final String stats = '/users/stats';
  final String progressReport = '/users/progress-report';
}
