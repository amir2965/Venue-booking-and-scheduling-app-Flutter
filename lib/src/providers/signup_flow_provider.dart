import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple provider to temporarily store date of birth during the signup flow
/// This is used to pass date of birth from signup screen to profile setup screen
final signupDateOfBirthProvider = StateProvider<DateTime?>((ref) => null);
