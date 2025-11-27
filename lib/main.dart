import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/services/image_upload_service.dart';

// Provider to control app rebuilds
final appKeyProvider = StateProvider<UniqueKey>((ref) => UniqueKey());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Storage
  await ImageUploadService.initializeStorage();

  runApp(
    const ProviderScope(
      child: _AppWithKey(),
    ),
  );
}

class _AppWithKey extends ConsumerWidget {
  const _AppWithKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(appKeyProvider);
    return BilliardsHubApp(key: key);
  }
}
