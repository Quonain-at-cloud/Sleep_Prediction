import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:light/light.dart';
import 'package:permission_handler/permission_handler.dart';

/// A simple service that gathers environmental metrics:
/// 1. Ambient light (lux)
/// 2. Environmental noise (dB)
/// 3. Ambient temperature (°C) – via Open-Meteo free API using current GPS location.
///
/// All readings are exposed via streams so that UI can update reactively.
class EnvironmentService {
  // ----- Light sensor -----
  final StreamController<double> _luxController = StreamController.broadcast();
  StreamSubscription<int>? _lightSub;

  // ----- Noise sensor -----
  final NoiseMeter _noiseMeter = NoiseMeter();
  StreamSubscription<NoiseReading>? _noiseSub;
  final StreamController<double> _dbController = StreamController.broadcast();

  // ----- Temperature -----
  final StreamController<double> _tempController = StreamController.broadcast();
  Timer? _tempTimer;

  EnvironmentService() {
    _initLightSensor();
    _initNoiseSensor(); // now async but fire-and-forget
    _initTemperatureLoop();
  }

  // Public streams
  Stream<double> get luxStream => _luxController.stream;
  Stream<double> get dbStream => _dbController.stream;
  Stream<double> get temperatureStream => _tempController.stream;

  // ---------------- Private ----------------
  void _initLightSensor() {
    try {
      final light = Light();
      _lightSub = light.lightSensorStream.listen((int lux) {
        _luxController.add(lux.toDouble());
      });
    } catch (_) {
      // On some devices the light sensor might not be available
      if (kDebugMode) {
        print('⚠️ Ambient light sensor not available');
      }
    }
  }

  Future<void> _initNoiseSensor() async {
    // Ensure mic permission first
    final status = await Permission.microphone.status;
    PermissionStatus finalStatus = status;
    if (!status.isGranted) {
      finalStatus = await Permission.microphone.request();
    }

    if (!finalStatus.isGranted) {
      if (kDebugMode) {
        print('⚠️ Microphone permission denied – noise sensor disabled');
      }
      return;
    }

    try {
      _noiseSub = _noiseMeter.noise.listen((NoiseReading reading) {
        _dbController.add(reading.meanDecibel);
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to start noise sensor: $e');
      }
    }
  }


  void _initTemperatureLoop() {
    // Immediately fetch once, then every 10 minutes
    _fetchTemperature();
    _tempTimer = Timer.periodic(const Duration(minutes: 10), (_) => _fetchTemperature());
  }

  Future<void> _fetchTemperature() async {
    try {
      final hasPerm = await _ensureLocationPerm();
      if (!hasPerm) return;
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final lat = position.latitude;
      final lon = position.longitude;
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final temp = (data['current_weather']?['temperature'])?.toDouble();
        if (temp != null) _tempController.add(temp);
      }
    } catch (e) {
      if (kDebugMode) print('Temperature fetch failed: $e');
    }
  }

  Future<bool> _ensureLocationPerm() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  // Cleanup
  void dispose() {
    _lightSub?.cancel();
    _noiseSub?.cancel();
    _tempTimer?.cancel();
    _luxController.close();
    _dbController.close();
    _tempController.close();
  }
}
