import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiards_hub/src/providers/mongodb_provider.dart';
import 'package:billiards_hub/src/models/player_profile.dart';
import 'package:billiards_hub/src/models/user.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MongoDB Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MongoDBTestScreen(),
    );
  }
}

class MongoDBTestScreen extends ConsumerStatefulWidget {
  const MongoDBTestScreen({super.key});

  @override
  ConsumerState<MongoDBTestScreen> createState() => _MongoDBTestScreenState();
}

class _MongoDBTestScreenState extends ConsumerState<MongoDBTestScreen> {
  String _status = 'Not connected';
  String _testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
  PlayerProfile? _savedProfile;

  Future<void> _testConnection() async {
    final mongoDBService = ref.read(mongoDBServiceProvider);

    setState(() {
      _status = 'Connecting...';
    });

    try {
      final isConnected = await mongoDBService.checkConnectivity();
      setState(() {
        _status = isConnected ? 'Connected!' : 'Connection failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _testSaveProfile() async {
    final mongoDBService = ref.read(mongoDBServiceProvider);

    setState(() {
      _status = 'Saving profile...';
    });

    try {
      final testProfile = PlayerProfile(
        user: User(
          id: _testUserId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        firstName: 'Test',
        lastName: 'User',
        bio: 'Test User Profile',
        skillLevel: 3.5,
        skillTier: 'Intermediate',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Test Location',
        availability: {
          'Monday': ['Evening'],
          'Saturday': ['Afternoon'],
        },
        experiencePoints: 1000,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      await mongoDBService.createProfile(testProfile);

      setState(() {
        _status = 'Profile saved!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error saving: $e';
      });
    }
  }

  Future<void> _testGetProfile() async {
    final mongoDBService = ref.read(mongoDBServiceProvider);

    setState(() {
      _status = 'Getting profile...';
    });

    try {
      final profile = await mongoDBService.getProfile(_testUserId);

      setState(() {
        _savedProfile = profile;
        _status = profile != null ? 'Profile loaded!' : 'Profile not found';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kIsWeb ? 'MongoDB Web Test' : 'MongoDB Local Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Status: $_status',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Test User ID: $_testUserId',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testSaveProfile,
              child: const Text('Save Test Profile'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testGetProfile,
              child: const Text('Get Test Profile'),
            ),
            if (_savedProfile != null) ...[
              const SizedBox(height: 16),
              const Text('Loaded Profile:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${_savedProfile!.user.id}'),
                      Text('Name: ${_savedProfile!.firstName}'),
                      Text('Skill Level: ${_savedProfile!.skillLevel}'),
                      Text('Location: ${_savedProfile!.preferredLocation}'),
                      Text('Bio: ${_savedProfile!.bio}'),
                      Text(
                          'Game Types: ${_savedProfile!.preferredGameTypes.join(", ")}'),
                      Text(
                          'Experience: ${_savedProfile!.experiencePoints} points'),
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
