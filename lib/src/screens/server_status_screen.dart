import 'package:flutter/material.dart';
import '../services/server_status_service.dart';
import '../services/api_config.dart';
import '../services/username_service_new.dart'; // Direct import for UsernameService

class ServerStatusScreen extends StatefulWidget {
  static const routeName = '/server-status';

  const ServerStatusScreen({Key? key}) : super(key: key);

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  final ServerStatusService _serverStatusService = ServerStatusService();
  final UsernameService _usernameService =
      UsernameService(); // Directly use the constructor

  Map<String, dynamic> _serverStatus = {
    'isConnected': false,
    'serverUp': false,
    'message': 'Not checked yet',
    'details': ''
  };
  String? _workingServerUrl;
  bool _isChecking = false;
  String _usernameToCheck = '';
  String _usernameCheckResult = '';

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final status = await _serverStatusService.checkServerStatus();
      setState(() {
        _serverStatus = status;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _serverStatus = {
          'isConnected': false,
          'serverUp': false,
          'message': 'Error checking server status',
          'details': e.toString()
        };
        _isChecking = false;
      });
    }
  }

  Future<void> _findWorkingServer() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final url = await _serverStatusService.findWorkingServerUrl();
      setState(() {
        _workingServerUrl = url;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _workingServerUrl = null;
        _isChecking = false;
      });
    }
  }

  Future<void> _checkUsername() async {
    if (_usernameToCheck.isEmpty) return;

    setState(() {
      _isChecking = true;
      _usernameCheckResult = 'Checking...';
    });

    try {
      final isAvailable =
          await _usernameService.isUsernameAvailable(_usernameToCheck);
      setState(() {
        _usernameCheckResult =
            'Username "${_usernameToCheck}" is ${isAvailable ? 'available' : 'not available'}';
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _usernameCheckResult = 'Error checking username: ${e.toString()}';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Current API URL: ${ApiConfig.baseUrl}'),
                    const SizedBox(height: 8),
                    Text('Device Platform: ${Theme.of(context).platform}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _serverStatus['isConnected']
                              ? Icons.wifi
                              : Icons.wifi_off,
                          color: _serverStatus['isConnected']
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Network Connection: ${_serverStatus['isConnected'] ? 'Connected' : 'Disconnected'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _serverStatus['serverUp']
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: _serverStatus['serverUp']
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Server Status: ${_serverStatus['serverUp'] ? 'Online' : 'Offline'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Status Message: ${_serverStatus['message']}'),
                    const SizedBox(height: 8),
                    Text('Details: ${_serverStatus['details']}'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isChecking ? null : _checkServerStatus,
                          child: Text(_isChecking
                              ? 'Checking...'
                              : 'Check Server Status'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isChecking ? null : _findWorkingServer,
                          child: Text(_isChecking
                              ? 'Searching...'
                              : 'Find Working Server'),
                        ),
                      ],
                    ),
                    if (_workingServerUrl != null) ...[
                      const SizedBox(height: 8),
                      Text('Working Server URL: $_workingServerUrl'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username Check Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Username to check',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _usernameToCheck = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isChecking ? null : _checkUsername,
                      child:
                          Text(_isChecking ? 'Checking...' : 'Check Username'),
                    ),
                    if (_usernameCheckResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(_usernameCheckResult),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
