import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user.dart';

abstract class AuthService {
  /// Get the current authenticated user
  User? get currentUser;

  /// Stream of auth state changes
  Stream<User?> authStateChanges();

  /// Get the current user
  Future<User?> getCurrentUser();

  /// Sign in with email and password
  Future<User> signInWithEmailAndPassword(String email, String password);

  /// Create user with email and password
  Future<User> createUserWithEmailAndPassword(String email, String password);

  /// Sign in with Google
  Future<User> signInWithGoogle();

  /// Sign in with Facebook
  Future<User> signInWithFacebook();

  /// Sign out the current user
  Future<void> signOut();

  /// Update the user's display name
  /// Returns true if successful
  Future<bool> updateUserDisplayName(String displayName);

  /// Set the current user after login
  void setCurrentUser(User user);

  /// Clear the current user after logout
  void clearCurrentUser();
}

// Firebase implementation
class FirebaseAuthService implements AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '428298560491-web-client-id.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Convert Firebase User to our custom User model
  User? _userFromFirebaseUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  Future<firebase_auth.UserCredential> _signInWithGoogleWeb() async {
    // Create a new provider
    firebase_auth.GoogleAuthProvider googleProvider =
        firebase_auth.GoogleAuthProvider();

    // Add scopes if needed
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    // Trigger the sign-in flow directly with Firebase Auth
    return await _firebaseAuth.signInWithPopup(googleProvider);
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return _userFromFirebaseUser(firebaseUser);
  }

  @override
  Future<bool> updateUserDisplayName(String displayName) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.reload(); // Reload to get updated profile
        return true;
      }
    } catch (e) {
      debugPrint('Error updating user display name: $e');
    }
    return false;
  }

  @override
  void setCurrentUser(User user) {
    // This method is intentionally left blank for FirebaseAuthService
  }

  @override
  void clearCurrentUser() {
    // This method is intentionally left blank for FirebaseAuthService
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    return _userFromFirebaseUser(firebaseUser);
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      final user = _userFromFirebaseUser(userCredential.user);
      if (user == null) {
        throw Exception('Failed to sign in with email and password');
      }
      return user;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        // Reload user to get updated information
        await userCredential.user!.reload();
      }

      final firebaseUser = _firebaseAuth.currentUser;
      final user = _userFromFirebaseUser(firebaseUser);

      if (user == null) {
        throw Exception('Failed to create user with email and password');
      }
      return user;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final userCredential = await _signInWithGoogleWeb();
        final user = _userFromFirebaseUser(userCredential.user);
        if (user == null) {
          throw Exception('Failed to sign in with Google');
        }
        return user;
      } else {
        // Use GoogleSignIn package on mobile platforms
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google sign in aborted by user');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        final user = _userFromFirebaseUser(userCredential.user);

        if (user == null) {
          throw Exception('Failed to sign in with Google');
        }
        return user;
      }
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<User> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook sign-in failed or was cancelled');
      }

      // Create a credential from the access token
      final firebase_auth.AuthCredential credential =
          firebase_auth.FacebookAuthProvider.credential(
              result.accessToken!.token);

      // Sign in with the credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = _userFromFirebaseUser(userCredential.user);
      if (user == null) {
        throw Exception('Failed to sign in with Facebook');
      }
      return user;
    } catch (e) {
      throw Exception('Facebook sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _firebaseAuth.signOut();

    if (kIsWeb) {
      html.window.location.reload();
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_userFromFirebaseUser);
  }
}

// Mock implementations - keeping these for development/testing purposes
class MockAuthService implements AuthService {
  User? _currentUser;

  final Map<String, String> _mockUsers = {
    'test@example.com': 'password123',
    'user@example.com': 'password456',
  };

  @override
  User? get currentUser => _currentUser;

  @override
  Future<bool> updateUserDisplayName(String displayName) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(displayName: displayName);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  void setCurrentUser(User user) {
    _currentUser = user;
  }

  @override
  void clearCurrentUser() {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if user exists and password matches
    if (_mockUsers.containsKey(email) && _mockUsers[email] == password) {
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        emailVerified: true,
      );
      return _currentUser!;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if user already exists
    if (_mockUsers.containsKey(email)) {
      throw Exception('User already exists with this email');
    }

    // Create new user
    _mockUsers[email] = password;
    _currentUser = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      emailVerified: false,
    );

    return _currentUser!;
  }

  @override
  Future<User> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create mock Google user
    _currentUser = User(
      id: 'google-${DateTime.now().millisecondsSinceEpoch}',
      email: 'google_user@gmail.com',
      displayName: 'Google User',
      photoUrl: 'https://picsum.photos/200',
      emailVerified: true,
    );

    return _currentUser!;
  }

  @override
  Future<User> signInWithFacebook() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create mock Facebook user
    _currentUser = User(
      id: 'facebook-${DateTime.now().millisecondsSinceEpoch}',
      email: 'facebook_user@example.com',
      displayName: 'Facebook User',
      photoUrl: 'https://picsum.photos/200',
      emailVerified: true,
    );

    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
  }

  @override
  Stream<User?> authStateChanges() {
    // Create a StreamController to simulate auth state changes
    final controller = StreamController<User?>.broadcast();

    // Add the current user state to the stream
    controller.add(_currentUser);

    // Return the stream
    return controller.stream;
  }
}

// Persistent Mock Auth Service - Extends MockAuthService to add persistence
class PersistentMockAuthService extends MockAuthService {
  static const String _userKey = 'current_user';

  @override
  Future<User?> getCurrentUser() async {
    // Try to get user from shared preferences first
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        // If there's an error parsing, clear the stored user
        await prefs.remove(_userKey);
      }
    }

    // Fall back to parent implementation
    return super.getCurrentUser();
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Call parent implementation
    final user = await super.signInWithEmailAndPassword(email, password);

    // Persist the user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    return user;
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    // Call parent implementation
    final user = await super.createUserWithEmailAndPassword(email, password,
        displayName: displayName);

    // Persist the user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    return user;
  }

  @override
  Future<User> signInWithGoogle() async {
    // Call parent implementation
    final user = await super.signInWithGoogle();

    // Persist the user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    return user;
  }

  @override
  Future<User> signInWithFacebook() async {
    // Call parent implementation
    final user = await super.signInWithFacebook();

    // Persist the user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));

    return user;
  }

  @override
  Future<void> signOut() async {
    // Call parent implementation
    await super.signOut();

    // Clear persisted user
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<bool> updateUserDisplayName(String displayName) async {
    // Call parent implementation to update the user
    final success = await super.updateUserDisplayName(displayName);

    if (success && _currentUser != null) {
      try {
        // Persist the updated user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(_currentUser!.toJson()));
        return true;
      } catch (e) {
        return false;
      }
    }

    return success;
  }
}
