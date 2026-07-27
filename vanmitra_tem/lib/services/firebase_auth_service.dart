import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_database.dart';

/// Wraps FirebaseAuth Email/Password and Firestore user-doc fetching.
class FirebaseAuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Email / Password Flow ──────────────────────────────────────────────

  /// Login with email and password
  Future<fb_auth.UserCredential> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    } catch (e) {
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Register a new user and create their Firestore document
  Future<fb_auth.UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    required String villageId,
  }) async {
    fb_auth.UserCredential? credential;

    try {
      // 1. Create the user in Firebase Auth
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Registration failed.');

      // 2. Create the user document in Firestore (requires updated security rules)
      await _createUserProfile(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        villageId: villageId,
      );

      return credential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    } on FirebaseException catch (e) {
      await _rollbackAuthUser(credential?.user);
      throw Exception(_firestoreError(e));
    } catch (e) {
      await _rollbackAuthUser(credential?.user);
      if (e is Exception) rethrow;
      throw Exception('Registration failed. Please try again.');
    }
  }

  /// Creates a Firestore profile for an authenticated user who is missing one.
  /// Used to recover accounts where Auth succeeded but profile creation failed.
  Future<Map<String, dynamic>> ensureUserProfile({
    required String uid,
    required String email,
    String? name,
    String? role,
    String? villageId,
  }) async {
    final existing = await getFirestoreUser(uid);
    if (existing != null) return existing;

    final profile = {
      'email': email.trim(),
      'name': (name?.trim().isNotEmpty == true)
          ? name!.trim()
          : email.split('@').first,
      'role': role ?? 'villager',
      'villageId': villageId ?? '',
      'preferredLanguage': 'mr',
      'createdAt': FieldValue.serverTimestamp(),
      'hasFaceEnrolled': false,
    };

    try {
      await _db.collection('users').doc(uid).set(profile);
    } on FirebaseException catch (e) {
      throw Exception(_firestoreError(e));
    }

    // Re-fetch so server timestamps are resolved when possible.
    return await getFirestoreUser(uid) ?? profile;
  }

  // ─── Claims & User Data ──────────────────────────────────────────────────

  /// Read Firebase Custom Claims (legacy/optional now that we use Firestore for role directly)
  Future<Map<String, dynamic>?> getCustomClaims({bool forceRefresh = true}) async {
    final result = await _auth.currentUser?.getIdTokenResult(forceRefresh);
    return result?.claims;
  }

  /// Fetch the Firestore users/{uid} document.
  Future<Map<String, dynamic>?> getFirestoreUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } on FirebaseException catch (e) {
      throw Exception(_firestoreError(e));
    }
  }

  /// Save FCM device token to Firestore so Cloud Functions can push notifications.
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'deviceTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {
      // Non-fatal: FCM token save failure should not crash the app
    }
  }

  // ─── Session ─────────────────────────────────────────────────────────────

  /// Sign out from Firebase and clear the local Hive user box.
  Future<void> signOut() async {
    await _auth.signOut();
    final box = Hive.box<Map>(HiveDatabase.userBox);
    await box.clear();
  }

  /// The current Firebase authenticated user (null if not signed in).
  fb_auth.User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes. Emits null on sign-out, User on sign-in.
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  // ─── Private Helpers ─────────────────────────────────────────────────────

  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
    required String villageId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'role': role,
      'villageId': villageId,
      'preferredLanguage': 'mr',
      'createdAt': FieldValue.serverTimestamp(),
      'hasFaceEnrolled': false,
    });
  }

  Future<void> _rollbackAuthUser(fb_auth.User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      // Best-effort cleanup when Firestore write fails after Auth signup.
    }
  }

  String _firestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Could not save your profile. Please deploy the latest Firestore rules and try again.';
    }
    return 'Database error (${e.code}). Please try again.';
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Your password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
