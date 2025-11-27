import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import './api_config.dart';

class ServerStatusService {
  final Connectivity _connectivity = Connectivity();
  final Duration _timeoutDuration = const Duration(seconds: 5);

  Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      // Check connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return {
          'isConnected': false,
          'serverUp': false,
          'message': 'No internet connection available',
          'details': 'Device is not connected to any network'
        };
      }

      // Try to access the server health endpoint
      final healthUrl = '${ApiConfig.baseUrl}/health';
      debugPrint('Checking server health at: $healthUrl');

      try {
        final response = await http
            .get(
              Uri.parse(healthUrl),
              headers: ApiConfig.headers,
            )
            .timeout(_timeoutDuration);

        debugPrint('Server health status: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            return {
              'isConnected': true,
              'serverUp': true,
              'message': 'Server is up and running',
              'details': data.toString()
            };
          } catch (parseError) {
            return {
              'isConnected': true,
              'serverUp': true,
              'message': 'Server responded but with invalid data',
              'details': 'JSON parse error: $parseError'
            };
          }
        } else {
          return {
            'isConnected': true,
            'serverUp': false,
            'message':
                'Server responded with error code: ${response.statusCode}',
            'details': response.body
          };
        }
      } on TimeoutException {
        return {
          'isConnected': true,
          'serverUp': false,
          'message': 'Server connection timed out',
          'details': 'Request exceeded $_timeoutDuration timeout'
        };
      } catch (e) {
        return {
          'isConnected': true,
          'serverUp': false,
          'message': 'Failed to connect to server',
          'details': e.toString()
        };
      }
    } catch (e) {
      return {
        'isConnected': false,
        'serverUp': false,
        'message': 'Error checking server status',
        'details': e.toString()
      };
    }
  }

  // Helper method to test various server URLs to find one that works
  Future<String?> findWorkingServerUrl() async {
    final List<String> possibleUrls = [
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://10.0.2.2:5000',
      // Add any other potential URLs you want to try
    ];

    for (final url in possibleUrls) {
      try {
        debugPrint('Trying server URL: $url/health');
        final response = await http
            .get(
              Uri.parse('$url/health'),
              headers: ApiConfig.headers,
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          debugPrint('Found working server URL: $url');
          return url;
        }
      } catch (e) {
        debugPrint('URL $url failed: $e');
      }
    }

    return null;
  }

  // Special web-compatible check for username availability that uses a different approach for web platforms
  Future<Map<String, dynamic>> checkUsernameAvailabilityDirect(
      String username) async {
    if (username.trim().isEmpty) {
      return {
        'success': false,
        'isAvailable': false,
        'message': 'Username cannot be empty',
        'details': 'Input validation failed'
      };
    }

    try {
      // Use different approach for web platform
      String url;

      if (kIsWeb) {
        // Try to use window.fetch instead of XMLHttpRequest for web
        // This is a workaround URL for web that will be handled by our special logic
        url =
            '${ApiConfig.baseUrl}/api/username/check?username=${Uri.encodeComponent(username)}&_=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        url =
            '${ApiConfig.baseUrl}/api/username/check?username=${Uri.encodeComponent(username)}';
      }

      debugPrint('Checking username availability at: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...ApiConfig.headers,
          'X-Platform': kIsWeb ? 'web' : 'app',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(_timeoutDuration);

      debugPrint('Username check status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final isAvailable = data['isAvailable'] ?? data['available'] ?? false;

          return {
            'success': true,
            'isAvailable': isAvailable,
            'message': 'Username check completed successfully',
            'details': 'Response: ${response.body}'
          };
        } catch (e) {
          return {
            'success': false,
            'isAvailable': false,
            'message': 'Failed to parse server response',
            'details': 'Parse error: $e, Body: ${response.body}'
          };
        }
      } else {
        return {
          'success': false,
          'isAvailable': false,
          'message': 'Server returned error status: ${response.statusCode}',
          'details': 'Response body: ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'isAvailable': false,
        'message': 'Error checking username availability',
        'details': 'Exception: $e'
      };
    }
  }
}
