import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './api_config.dart';

/// Custom exception for username-related errors
class UsernameServiceException implements Exception {
  final String message;
  final int? statusCode;
  final bool isConnectivityIssue;

  UsernameServiceException(this.message,
      {this.statusCode, this.isConnectivityIssue = false});

  @override
  String toString() => message;
}

class UsernameService {
  final Connectivity _connectivity = Connectivity();
  final String _pendingOperationsKey = 'pending_username_operations';
  final Duration _timeoutDuration =
      const Duration(seconds: 10); // Increased timeout
  final Duration _baseRetryDelay = const Duration(seconds: 1);
  final int _maxRetries = 3;
  String get baseUrl => '${ApiConfig.baseUrl}/api/username';

  UsernameService();

  void initialize() {
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

  /// Check server health before making any request
  Future<bool> isServerUp() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/health'),
            headers: ApiConfig.headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Server health check error: $e');
      return false;
    }
  }

  /// Check username availability with retries and proper error handling
  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;

    int retryCount = 0;

    while (retryCount <= _maxRetries) {
      try {
        // Check connectivity first
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          debugPrint('No internet connection available for username check');
          throw UsernameServiceException('No internet connection available',
              isConnectivityIssue: true);
        }

        // Print the URL being accessed for debugging
        final url = '$baseUrl/check?username=${Uri.encodeComponent(username)}';
        debugPrint('Checking username availability at: $url');

        // Try the server health check first
        final serverUp = await isServerUp();
        if (!serverUp) {
          debugPrint('Server health check failed, server appears to be down');
          throw UsernameServiceException('Username server is not responding',
              isConnectivityIssue: true);
        }

        final response = await http
            .get(
              Uri.parse(url),
              headers: ApiConfig.headers,
            )
            .timeout(_timeoutDuration);

        debugPrint('Username check response status: ${response.statusCode}');
        debugPrint('Username check response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['isAvailable'] ?? data['available'] ?? false;
        }

        if (response.statusCode >= 500) {
          throw UsernameServiceException('Server error: ${response.statusCode}',
              statusCode: response.statusCode, isConnectivityIssue: true);
        }

        throw UsernameServiceException('API error: ${response.statusCode}',
            statusCode: response.statusCode);
      } on TimeoutException {
        if (retryCount == _maxRetries) {
          throw UsernameServiceException(
              'Request timed out after $_maxRetries retries',
              isConnectivityIssue: true);
        }
        await Future.delayed(_baseRetryDelay * (retryCount + 1));
        retryCount++;
        continue;
      } catch (e) {
        if (e is UsernameServiceException) {
          if (e.isConnectivityIssue && retryCount < _maxRetries) {
            await Future.delayed(_baseRetryDelay * (retryCount + 1));
            retryCount++;
            continue;
          }
          rethrow;
        }
        throw UsernameServiceException('Unexpected error: $e');
      }
    }

    throw UsernameServiceException(
        'Failed to check username after $_maxRetries retries');
  }

  /// Reserve a username with retries and proper error handling
  Future<bool> reserveUsername(String username, String userId) async {
    int retryCount = 0;

    while (retryCount <= _maxRetries) {
      try {
        // Check connectivity first
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          await _addPendingOperation('reserve', username, userId);
          return true;
        }

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

        if (response.statusCode == 200) {
          return true;
        }

        if (response.statusCode >= 500) {
          if (retryCount < _maxRetries) {
            await Future.delayed(_baseRetryDelay * (retryCount + 1));
            retryCount++;
            continue;
          }
          // If all retries failed, handle optimistically
          await _addPendingOperation('reserve', username, userId);
          return true;
        }

        throw UsernameServiceException('Failed to reserve username',
            statusCode: response.statusCode);
      } on TimeoutException {
        if (retryCount < _maxRetries) {
          await Future.delayed(_baseRetryDelay * (retryCount + 1));
          retryCount++;
          continue;
        }
        // If all retries failed, handle optimistically
        await _addPendingOperation('reserve', username, userId);
        return true;
      } catch (e) {
        if (e is UsernameServiceException) rethrow;
        await _addPendingOperation('reserve', username, userId);
        return true;
      }
    }

    // Final fallback
    await _addPendingOperation('reserve', username, userId);
    return true;
  }

  /// Update a username with retries and proper error handling
  Future<bool> updateUsername(
      String oldUsername, String newUsername, String userId) async {
    int retryCount = 0;

    while (retryCount <= _maxRetries) {
      try {
        // Check connectivity first
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          await _addPendingOperation('update', newUsername, userId,
              oldUsername: oldUsername);
          return true;
        }

        final response = await http
            .post(
              Uri.parse('$baseUrl/update'),
              headers: {
                'Content-Type': 'application/json',
                ...ApiConfig.headers,
              },
              body: json.encode({
                'oldUsername': oldUsername,
                'newUsername': newUsername,
                'userId': userId,
              }),
            )
            .timeout(_timeoutDuration);

        debugPrint('Update username response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          return true;
        }

        if (response.statusCode >= 500) {
          if (retryCount < _maxRetries) {
            await Future.delayed(_baseRetryDelay * (retryCount + 1));
            retryCount++;
            continue;
          }
          // If all retries failed, handle optimistically
          await _addPendingOperation('update', newUsername, userId,
              oldUsername: oldUsername);
          return true;
        }

        throw UsernameServiceException('Failed to update username',
            statusCode: response.statusCode);
      } on TimeoutException {
        if (retryCount < _maxRetries) {
          await Future.delayed(_baseRetryDelay * (retryCount + 1));
          retryCount++;
          continue;
        }
        // If all retries failed, handle optimistically
        await _addPendingOperation('update', newUsername, userId,
            oldUsername: oldUsername);
        return true;
      } catch (e) {
        if (e is UsernameServiceException) rethrow;
        await _addPendingOperation('update', newUsername, userId,
            oldUsername: oldUsername);
        return true;
      }
    }

    // Final fallback
    await _addPendingOperation('update', newUsername, userId,
        oldUsername: oldUsername);
    return true;
  }

  /// Add a pending operation to be processed when back online
  Future<void> _addPendingOperation(String type, String username, String userId,
      {String? oldUsername}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingOperationsKey);
      final List<Map<String, dynamic>> pendingOps = [];

      if (pendingOpsJson != null) {
        final decoded = json.decode(pendingOpsJson) as List;
        pendingOps.addAll(decoded.cast<Map<String, dynamic>>());
      }

      pendingOps.add({
        'type': type,
        'username': username,
        'userId': userId,
        if (oldUsername != null) 'oldUsername': oldUsername,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_pendingOperationsKey, json.encode(pendingOps));
      debugPrint('Added pending operation: $type for $username');
    } catch (e) {
      debugPrint('Error adding pending operation: $e');
    }
  }

  /// Process pending operations when back online
  Future<void> _processPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingOperationsKey);
      if (pendingOpsJson == null) return;

      final List<dynamic> pendingOps = json.decode(pendingOpsJson);
      if (pendingOps.isEmpty) return;

      // Check if server is available
      if (!await isServerUp()) {
        debugPrint('Server is not available, keeping pending operations');
        return;
      }

      debugPrint('Processing ${pendingOps.length} pending operations');

      for (final op in pendingOps) {
        try {
          switch (op['type']) {
            case 'reserve':
              await http.post(
                Uri.parse('$baseUrl/reserve'),
                headers: {
                  'Content-Type': 'application/json',
                  ...ApiConfig.headers,
                },
                body: json.encode({
                  'username': op['username'],
                  'userId': op['userId'],
                }),
              );
              break;

            case 'update':
              await http.post(
                Uri.parse('$baseUrl/update'),
                headers: {
                  'Content-Type': 'application/json',
                  ...ApiConfig.headers,
                },
                body: json.encode({
                  'oldUsername': op['oldUsername'],
                  'newUsername': op['username'],
                  'userId': op['userId'],
                }),
              );
              break;
          }
        } catch (e) {
          debugPrint('Error processing operation: $e');
          // Keep the failed operation in the list
          continue;
        }
      }

      // Clear successfully processed operations
      await prefs.remove(_pendingOperationsKey);
      debugPrint('Successfully processed all pending operations');
    } catch (e) {
      debugPrint('Error processing pending operations: $e');
    }
  }
}
