import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mongodb_provider.dart';
import '../../models/player_profile.dart';
import '../../models/user.dart';

class WebMongoDBTestScreen extends ConsumerStatefulWidget {
  const WebMongoDBTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WebMongoDBTestScreen> createState() =>
      _WebMongoDBTestScreenState();
}

class _WebMongoDBTestScreenState extends ConsumerState<WebMongoDBTestScreen> {
  String _status = 'Not tested';
  final _testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
  PlayerProfile? _savedProfile;
  final TextEditingController _nameController =
      TextEditingController(text: 'Test User');
  final TextEditingController _locationController =
      TextEditingController(text: 'Test Location');

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _status = 'Testing connection...';
    });

    try {
      final mongoDBService = ref.read(mongoDBServiceProvider);
      final isConnected = await mongoDBService.checkConnectivity();

      setState(() {
        _status = isConnected ? 'Connection successful!' : 'Connection failed!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _status = 'Saving profile...';
    });

    try {
      final mongoDBService = ref.read(mongoDBServiceProvider);
      final profile = PlayerProfile(
        user: User(
          id: _testUserId,
          email: 'test@example.com',
          displayName: _nameController.text,
        ),
        firstName: _nameController.text.split(' ').first,
        lastName: _nameController.text.split(' ').length > 1
            ? _nameController.text.split(' ').sublist(1).join(' ')
            : 'TestLastName',
        username: 'test_${_testUserId.substring(0, 8)}',
        bio: 'Test Profile',
        skillLevel: 3.0,
        skillTier: 'Intermediate',
        preferredGameTypes: ['8 Ball'],
        preferredLocation: _locationController.text,
        availability: {
          'Monday': ['Evening'],
          'Saturday': ['Afternoon'],
        },
        experiencePoints: 1000,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      await mongoDBService.createProfile(profile);

      setState(() {
        _status = 'Profile saved successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error saving profile: $e';
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _status = 'Loading profile...';
    });

    try {
      final mongoDBService = ref.read(mongoDBServiceProvider);
      final profile = await mongoDBService.getProfile(_testUserId);

      setState(() {
        _savedProfile = profile;
        _status = profile != null
            ? 'Profile loaded successfully!'
            : 'No profile found!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web MongoDB Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Test User ID: $_testUserId'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Test Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Load Profile'),
                  ),
                ),
              ],
            ),
            if (_savedProfile != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Loaded Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_savedProfile!.firstName}'),
                      Text('Location: ${_savedProfile!.preferredLocation}'),
                      Text('Skill Level: ${_savedProfile!.skillLevel}'),
                      Text('ID: ${_savedProfile!.user.id}'),
                      Text(
                          'Experience Points: ${_savedProfile!.experiencePoints}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
