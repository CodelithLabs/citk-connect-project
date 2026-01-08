import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cit_parser.dart'; // Ensure this points to your CITParser file

// ⚡ GLOBAL PROVIDER
final authServiceProvider = StateNotifierProvider<AuthService, AsyncValue<User?>>((ref) {
  return AuthService();
});

class AuthService extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 👂 LISTEN TO AUTH CHANGES INSTANTLY
  AuthService() : super(const AsyncValue.loading()) {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        // 🤖 AUTONOMOUS SYNC: Run the parser every time they login
        await _syncSmartData(user);
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    }, onError: (e, st) {
      state = AsyncValue.error(e, st);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧠 THE BRAIN: AUTONOMOUS DATA SYNC
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _syncSmartData(User user) async {
    final email = user.email ?? "";
    final uid = user.uid;

    try {
      // 1. Check if this is a Driver (Manual Override)
      // Drivers don't get parsed by the CIT Parser
      final docSnapshot = await _db.collection('users').doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data()?['role'] == 'driver') {
        // Update last login only
        await _db.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        return; 
      }

      // 2. Parse Data (The "Elon Musk" Logic)
      // This runs locally, so it works even if Firestore is slow.
      final parsedData = CITParser.parseEmail(email);

      // 3. Heal the Database
      // We use set(..., SetOptions(merge: true)) to ensure we never lose existing data
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': user.displayName ?? 'Unknown',
        'photoURL': user.photoURL,
        'role': parsedData.role,         // Auto-detected
        'batch': parsedData.batch,       // Auto-detected
        'branch': parsedData.branch,     // Auto-detected
        'department': parsedData.department,
        'semester': parsedData.semester, // Auto-calculated based on TODAY'S DATE
        'rollNumber': parsedData.rollNumber,
        'isGraduated': parsedData.isGraduated,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      // Fail silently on sync errors (don't block login)
      // The user can still use the app, we'll catch them next time.
      print("⚠️ Auto-Sync Warning: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌍 PRIMARY: GOOGLE SIGN IN (Student/Faculty/Aspirant)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // 1. Native Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null); // User cancelled
        return;
      }

      // 2. Authenticate with Firebase
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      // Logic continues in the listener above...
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚗 SECONDARY: DRIVER REGISTRATION (Manual)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> registerDriver({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Create Auth
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user!;

      await user.updateDisplayName(name);

      // 2. Set Explicit Role
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': name,
        'role': 'driver', // 🔒 LOCKED ROLE
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isApproved': false, // Security: Admin must approve drivers
      });
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Let UI handle the error message
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔑 DRIVER LOGIN
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> signInWithEmail({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}