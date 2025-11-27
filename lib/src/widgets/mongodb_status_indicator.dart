import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mongodb_provider.dart';

class MongoDBStatusIndicator extends ConsumerStatefulWidget {
  const MongoDBStatusIndicator({Key? key}) : super(key: key);

  @override
  ConsumerState<MongoDBStatusIndicator> createState() =>
      _MongoDBStatusIndicatorState();
}

class _MongoDBStatusIndicatorState
    extends ConsumerState<MongoDBStatusIndicator> {
  bool _isConnected = false;
  bool _isCheckingConnection = false;
  String _statusMessage = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (_isCheckingConnection) return;

    setState(() {
      _isCheckingConnection = true;
      _statusMessage = 'Checking...';
    });

    try {
      final mongoDBService = ref.read(mongoDBServiceProvider);
      final isConnected = await mongoDBService.checkConnectivity();

      setState(() {
        _isConnected = isConnected;
        _statusMessage = isConnected ? 'Connected' : 'Disconnected';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCheckingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'MongoDB Status: $_statusMessage',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isCheckingConnection ? null : _checkConnection,
              child: _isCheckingConnection
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
