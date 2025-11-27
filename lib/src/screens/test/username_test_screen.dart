import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../providers/username_provider.dart';

class UsernameTestScreen extends ConsumerStatefulWidget {
  const UsernameTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UsernameTestScreen> createState() => _UsernameTestScreenState();
}

class _UsernameTestScreenState extends ConsumerState<UsernameTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _userIdController = TextEditingController();

  String _responseText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userIdController.text = 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _responseText = 'Checking username availability...';
    });

    final usernameService = ref.read(usernameServiceProvider);

    try {
      final isAvailable = await usernameService
          .isUsernameAvailable(_usernameController.text.trim());

      setState(() {
        _isLoading = false;
        _responseText =
            'Username "${_usernameController.text.trim()}" is ${isAvailable ? "available" : "not available"}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = 'Error: $e';
      });
    }
  }

  Future<void> _reserveUsername() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _responseText = 'Reserving username...';
    });

    final usernameService = ref.read(usernameServiceProvider);

    try {
      final success = await usernameService.reserveUsername(
          _usernameController.text.trim(), _userIdController.text.trim());

      setState(() {
        _isLoading = false;
        _responseText = success
            ? 'Username "${_usernameController.text.trim()}" reserved successfully'
            : 'Failed to reserve username "${_usernameController.text.trim()}"';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = 'Error: $e';
      });
    }
  }

  Future<void> _directApiCall() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _responseText = 'Making direct API call...';
    });

    try {
      final baseUrl = 'http://10.0.2.2:5000/api/username';

      // Check username availability
      final checkUrl = Uri.parse(
          '$baseUrl/check?username=${Uri.encodeComponent(_usernameController.text.trim())}');
      final checkResponse = await http.get(
        checkUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      final checkData = jsonDecode(checkResponse.body);

      setState(() {
        _isLoading = false;
        _responseText = 'Direct API Response:\n'
            'Status: ${checkResponse.statusCode}\n'
            'Body: ${const JsonEncoder.withIndent('  ').convert(checkData)}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = 'Direct API Error: $e';
      });
    }
  }

  Future<void> _checkServerHealth() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Checking server health...';
    });

    final usernameService = ref.read(usernameServiceProvider);

    try {
      final isUp = await usernameService.isServerUp();

      setState(() {
        _isLoading = false;
        _responseText = isUp
            ? 'Server is up and running!'
            : 'Server is not responding. Please make sure it\'s running.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseText = 'Error checking server health: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Username Service Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter a username to test',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter a user ID for reserving',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a user ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkUsernameAvailability,
                    child: const Text('Check Availability'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _reserveUsername,
                    child: const Text('Reserve Username'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _directApiCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text('Direct API Call'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkServerHealth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Check Server Health'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Response:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Text(_responseText),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
