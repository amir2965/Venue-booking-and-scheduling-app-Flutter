import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_config.dart';

class UsernameService {
  final Connectivity _connectivity = Connectivity();
  final String _pendingOperationsKey = 'pending_username_operations';
  final Duration _timeoutDuration = const Duration(seconds: 5);

  String get baseUrl => '${ApiConfig.baseUrl}/api/username';

  UsernameService() {
    debugPrint('UsernameService initialized with baseUrl: $baseUrl');
    _initConnectivityMonitoring();
  }

  void _initConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) async {
      final isConnected = result != ConnectivityResult.none;
      debugPrint(
          'Network connectivity changed: ${isConnected ? 'Connected' : 'Disconnected'}');
      if (isConnected) {
        await _processPendingOperations();
      }
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;

    debugPrint('Checking availability for username: $username');

    try {
      // Check connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection available');
        return _checkUsernameLocallyAsBackup(username);
      }

      // Test the debug endpoint first for web platform
      if (kIsWeb) {
        try {
          final debugUrl =
              '${ApiConfig.baseUrl}/api/username/debug-check?username=${Uri.encodeComponent(username)}';
          debugPrint('Trying debug endpoint: $debugUrl');

          final debugResponse = await http.get(
            Uri.parse(debugUrl),
            headers: {
              ...ApiConfig.headers,
              'Access-Control-Allow-Origin': '*',
            },
          ).timeout(_timeoutDuration);

          debugPrint('Debug endpoint response: ${debugResponse.statusCode}');
          debugPrint('Debug endpoint body: ${debugResponse.body}');
        } catch (e) {
          debugPrint('Debug endpoint error: $e');
          // Continue even if debug endpoint fails - don't return error yet
        }
      }

      // Now try the actual check
      try {
        final checkUrl =
            '$baseUrl/check?username=${Uri.encodeComponent(username)}';
        debugPrint('Trying check endpoint: $checkUrl');

        final response = await http
            .get(
              Uri.parse(checkUrl),
              headers: ApiConfig.headers,
            )
            .timeout(_timeoutDuration);

        debugPrint('Username check response status: ${response.statusCode}');
        debugPrint('Username check response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final result = data['isAvailable'] ?? data['available'] ?? false;
          debugPrint(
              'Username "$username" is ${result ? 'available' : 'not available'}');
          return result;
        }

        // If we got a response but it's not 200, fall back to local check
        debugPrint('API returned non-200 status code: ${response.statusCode}');
        return _checkUsernameLocallyAsBackup(username);
      } catch (e) {
        debugPrint('Username check error: $e');
        // If API request fails completely, fall back to local check
        return _checkUsernameLocallyAsBackup(username);
      }
    } catch (e) {
      debugPrint('Overall username check error: $e');
      // Final fallback
      return _checkUsernameLocallyAsBackup(username);
    }
  }

  // Local fallback to check username when API is unavailable
  bool _checkUsernameLocallyAsBackup(String username) {
    debugPrint('Using local fallback for username check: $username');
    // Simple check - just ensure it's not empty and has minimum length
    final normalizedUsername = username.trim();
    return normalizedUsername.isNotEmpty && normalizedUsername.length >= 3;
  }

  Future<bool> reserveUsername(String username, String userId) async {
    debugPrint('Attempting to reserve username: $username for user: $userId');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reserve'),
            headers: {
              'Content-Type': 'application/json',
              ...ApiConfig.headers,
            },
            body: json.encode({
              'username': username,
              'userId': userId,
            }),
          )
          .timeout(_timeoutDuration);

      debugPrint('Reserve username response status: ${response.statusCode}');
      debugPrint('Reserve username response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      throw Exception('Failed to reserve username: ${response.statusCode}');
    } catch (e) {
      debugPrint('Reserve username error: $e');
      rethrow;
    }
  }

  /// Update a user's username
  Future<bool> updateUsername(
      String oldUsername, String newUsername, String userId) async {
    if (newUsername.trim().isEmpty) return false;

    debugPrint(
        'Updating username for user $userId from $oldUsername to: $newUsername');

    try {
      final isAvailable = await isUsernameAvailable(newUsername);
      if (!isAvailable) {
        debugPrint('Username $newUsername is not available');
        return false;
      }

      final uri = Uri.parse('$baseUrl/update');
      final response = await http
          .post(
            uri,
            headers: ApiConfig.headers,
            body: jsonEncode({
              'userId': userId,
              'oldUsername': oldUsername,
              'newUsername': newUsername,
            }),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        debugPrint('Username updated successfully');
        return true;
      } else {
        debugPrint(
            'Failed to update username: ${response.statusCode} - ${response.body}');

        // Store the operation for later if it's a connectivity issue
        if (response.statusCode >= 500 || response.statusCode == 0) {
          await _storePendingOperation('update', {
            'userId': userId,
            'oldUsername': oldUsername,
            'newUsername': newUsername,
          });
        }

        return false;
      }
    } catch (e) {
      debugPrint('Error updating username: $e');

      // Store the operation for later retry
      await _storePendingOperation('update', {
        'userId': userId,
        'oldUsername': oldUsername,
        'newUsername': newUsername,
      });

      return false;
    }
  }

  Future<bool> isServerUp() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/health'),
            headers: ApiConfig.headers,
          )
          .timeout(_timeoutDuration);

      debugPrint('Server health check status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Server health check body: ${response.body}');
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Server health check error: $e');
      return false;
    }
  }

  Future<void> _processPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingOperationsKey);
      if (pendingOpsJson == null) return;
      final List<dynamic> pendingOps = json.decode(pendingOpsJson);
      for (var op in pendingOps) {
        try {
          if (op['type'] == 'reserve') {
            await reserveUsername(op['username'], op['userId']);
          } else if (op['type'] == 'update') {
            await updateUsername(
                op['oldUsername'] ?? '', op['newUsername'], op['userId']);
          }
        } catch (e) {
          debugPrint('Error processing pending operation: $e');
        }
      }

      await prefs.remove(_pendingOperationsKey);
    } catch (e) {
      debugPrint('Error in _processPendingOperations: $e');
    }
  }

  Future<void> _storePendingOperation(
      String type, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingOperationsKey);
      final List<dynamic> pendingOps =
          pendingOpsJson != null ? json.decode(pendingOpsJson) : [];

      pendingOps.add({'type': type, ...data});
      await prefs.setString(_pendingOperationsKey, json.encode(pendingOps));
    } catch (e) {
      debugPrint('Error storing pending operation: $e');
    }
  }
}
