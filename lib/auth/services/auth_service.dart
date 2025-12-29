import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> build() {
    return _auth.authStateChanges();
  }

  // --- 1. Sign In (Email/Pass) ---
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // We do NOT set 'state = loading' here because that triggers the AuthGate to build a "Loading Screen"
    // which effectively "redirects" the user. We want the UI to handle the loading spinner locally.
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // --- 2. Sign Up (Email/Pass + Student Data) ---
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String department,
    required String semester,
  }) async {
    // A. Create Auth User
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // B. Save Student Profile to Firestore
    if (cred.user != null) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'department': department,
        'semester': semester,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Update Display Name
      await cred.user!.updateDisplayName(name);
    }
  }

  // --- 3. Google Sign In ---
  Future<void> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      UserCredential cred = await _auth.signInWithCredential(credential);

      // Check if it's a new user and save basic data if needed
      if (cred.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': cred.user!.displayName ?? 'Student',
          'email': cred.user!.email,
          'department': 'Unknown', // They can update this later in profile
          'semester': '1st',
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Throw it so the UI can catch it and show a Snackbar
      throw FirebaseAuthException(
        code: 'google-sign-in-failed', 
        message: e.toString()
      );
    }
  }

  // --- 4. Forgot Password ---
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- 5. Sign Out ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}