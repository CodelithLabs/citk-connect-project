import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ================================
/// PROVIDER
/// ================================
final authServiceProvider =
    StateNotifierProvider<AuthService, AsyncValue<User?>>((ref) {
  return AuthService();
});

/// ================================
/// AUTH SERVICE
/// ================================
class AuthService extends StateNotifier<AsyncValue<User?>> {
  AuthService() : super(const AsyncValue.data(null)) {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ============================================================
  // 1️⃣ GOOGLE SIGN-IN (Student / Faculty / Aspirant)
  // ============================================================
  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null); // User cancelled
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential cred =
          await _auth.signInWithCredential(credential);

      final User? user = cred.user;
      if (user != null) {
        await _saveUserToFirestore(user);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ============================================================
  // 2️⃣ EMAIL + PASSWORD SIGN-IN
  // ============================================================
  Future<void> signInWithEmailAndPassword(
      String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // 3️⃣ EMAIL SIGN-UP (Student Registration)
  // ============================================================
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String department,
    required String semester,
  }) async {
    final UserCredential cred =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return;

    await user.updateDisplayName(name);

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'department': department,
      'semester': semester,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // 4️⃣ DRIVER LOGIN (Anonymous)
  // ============================================================
  Future<void> signInAsDriver(String vehicleId) async {
    try {
      state = const AsyncValue.loading();

      final UserCredential cred =
          await _auth.signInAnonymously();
      final user = cred.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'role': 'driver',
          'vehicleId': vehicleId,
          'isActive': true,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ============================================================
  // 5️⃣ PASSWORD RESET
  // ============================================================
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ============================================================
  // 6️⃣ SIGN OUT
  // ============================================================
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  // ============================================================
  // 🔐 FIRESTORE USER SAVE (ROLE LOGIC)
  // ============================================================
  Future<void> _saveUserToFirestore(User user) async {
    final email = user.email ?? '';
    String role = 'aspirant';

    if (email.endsWith('@cit.ac.in')) {
      final prefix = email.split('@').first;
      final hasNumbers = RegExp(r'\d').hasMatch(prefix);
      role = hasNumbers ? 'student' : 'faculty';
    }

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'role': role,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
