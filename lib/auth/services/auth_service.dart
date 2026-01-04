import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'google_signin_config.dart';
import 'cit_parser.dart'; // Don't forget this import

final authServiceProvider =
    StateNotifierProvider<AuthService, AsyncValue<User?>>((ref) => AuthService());

class AuthService extends StateNotifier<AsyncValue<User?>> {
  // 🟢 OLD CODE: The constructor listener is crucial
  AuthService() : super(const AsyncValue.data(null)) {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        // ⚡ NEW FEATURE: Trigger the smart sync
        await _syncUserData(user);
      }
      state = AsyncValue.data(user);
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: googleClientId,
    scopes: ['email', 'profile'],
  );

  // ============================================================
  // 🧠 THE LOGIC MERGE: Intelligent Sync
  // ============================================================
  Future<void> _syncUserData(User user) async {
    final email = user.email ?? "";
    if (!email.endsWith("@cit.ac.in")) return;

    final userRef = _db.collection('users').doc(user.uid);
    
    try {
      // Check if user has "locked" their profile (Manual Override)
      final doc = await userRef.get();
      if (doc.exists && doc.data()?['isManualOverride'] == true) {
        return; 
      }

      // Parse Data
      final data = CITParser.parseEmail(email);

      // Data to Write
      Map<String, dynamic> updateData = {
        'uid': user.uid,
        'email': email,
        'role': data.role,
        'degree': data.degree,
        'branch': data.branch,
        'department': data.department,
        'batch': data.batch,
        'rollNumber': data.rollNumber,
        'isGraduated': data.isGraduated,
        'last_synced': FieldValue.serverTimestamp(),
      };

      // 🛡️ Safety: Only overwrite Semester if NOT manual override
      // (We already checked override above, but this double checks logic flow)
      updateData['semester'] = data.semester;

      await userRef.set(updateData, SetOptions(merge: true));

    } catch (e) {
      print("Sync Error: $e");
    }
  }

  // ============================================================
  // 1️⃣ GOOGLE SIGN IN (Faculty / Student / Aspirant)
  // ============================================================
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ============================================================
  // 2️⃣ EMAIL/PASSWORD LOGIN (Preserved from OLD CODE)
  // ============================================================
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ============================================================
  // 3️⃣ MANUAL STUDENT REGISTRATION (Preserved from OLD CODE)
  // ============================================================
  Future<void> signUpWithEmailAndPassword({
    required String email, required String password, required String name,
    required String department, required String semester,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName(name);
        
        // Save Manually - AND set 'isManualOverride' to true
        // This prevents the Parser from overwriting this data later
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'department': department,
          'semester': semester,
          'role': 'student',
          'isManualOverride': true, // 👈 CRITICAL ADDITION
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 4️⃣ DRIVER LOGIN (Preserved from OLD CODE)
  // ============================================================
  Future<void> signInAsDriver(String vehicleId) async {
    try {
      state = const AsyncValue.loading();
      final cred = await _auth.signInAnonymously();
      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
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
  // 5️⃣ UTILS (Preserved)
  // ============================================================
  Future<void> sendPasswordResetEmail(String email) async => 
      await _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}