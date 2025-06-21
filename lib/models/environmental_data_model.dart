class EnvironmentalData {
  final double? temperature;
  final double? humidity;
  final double? lightIntensity;
  final String? soundExposure;
  final double? noiseLevel;
  final String? airQuality;
  final String? sleepEnvironment;
  final String? sleepPosition;
  final String? notes;

  EnvironmentalData({
    this.temperature,
    this.humidity,
    this.lightIntensity,
    this.soundExposure,
    this.noiseLevel,
    this.airQuality,
    this.sleepEnvironment,
    this.sleepPosition,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'lightIntensity': lightIntensity,
      'soundExposure': soundExposure,
      'noiseLevel': noiseLevel,
      'airQuality': airQuality,
      'sleepEnvironment': sleepEnvironment,
      'sleepPosition': sleepPosition,
      'notes': notes,
    };
  }

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) {
    return EnvironmentalData(
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      lightIntensity: json['lightIntensity']?.toDouble(),
      soundExposure: json['soundExposure'],
      noiseLevel: json['noiseLevel']?.toDouble(),
      airQuality: json['airQuality'],
      sleepEnvironment: json['sleepEnvironment'],
      sleepPosition: json['sleepPosition'],
      notes: json['notes'],
    );
  }

  static List<String> get soundExposureOptions => [
    'Silent',
    'Quiet',
    'Moderate',
    'Loud',
    'Very Loud'
  ];

  static List<String> get airQualityOptions => [
    'Excellent',
    'Good',
    'Moderate',
    'Poor',
    'Very Poor'
  ];

  static List<String> get sleepEnvironmentOptions => [
    'Bedroom',
    'Living Room',
    'Hotel',
    'Other'
  ];

  static List<String> get sleepPositionOptions => [
    'Back',
    'Side',
    'Stomach',
    'Multiple'
  ];
}
