import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverAuthBackendProvider = Provider((ref) => DriverAuthBackend());

class DriverAuthBackend {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔒 Calls Server-Side Verification
  /// No hashing happens on the client.
  Future<void> verifyAndLoginDriver(String pin) async {
    try {
      final callable = _functions.httpsCallable('verifyDriverPin');

      // 1. Send Raw PIN (Protected by HTTPS)
      await callable.call(<String, dynamic>{
        'pin': pin,
      });

      // 2. Force Token Refresh to get new Permissions/Claims
      final user = _auth.currentUser;
      if (user != null) {
        await user.getIdToken(true); // true = forceRefresh
      }
    } on FirebaseFunctionsException catch (e) {
      // Map backend errors to UI messages
      throw Exception(e.message ?? "Verification Failed");
    }
  }
}
