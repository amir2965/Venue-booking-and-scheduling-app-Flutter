import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // For web applications - must match the server's CORS configuration
      // Use window.location.hostname to get the same host as the web app
      return 'http://127.0.0.1:5000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator needs special IP for localhost
      return 'http://10.0.2.2:5000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS simulator can use localhost
      return 'http://localhost:5000';
    } else if (Platform.isWindows) {
      // Windows desktop
      return 'http://127.0.0.1:5000'; // Use 127.0.0.1 for consistency
    } else {
      // Other platforms
      return 'http://127.0.0.1:5000';
    }
  }

  static Duration get defaultTimeout => const Duration(seconds: 10);

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
