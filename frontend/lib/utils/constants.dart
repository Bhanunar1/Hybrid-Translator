import 'package:flutter/foundation.dart';

class AppConstants {
  // Uses production URL in release builds (Play Store), and localhost for development.
  // TODO: Replace with your actual deployed backend URL
  static const String _productionUrl = 'https://api.hylator.com';
  static const String _devUrl = 'http://127.0.0.1:8000'; // 10.0.2.2 for emulator

  static const String apiBaseUrl = kReleaseMode ? _productionUrl : _devUrl;
  
  static const String appName = 'Hybrid Translator Pro';
  static const String appVersion = '3.0.0';
}
