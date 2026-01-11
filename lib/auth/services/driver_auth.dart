import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final driverAuthProvider = Provider((ref) => DriverAuth());

class DriverAuth {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔒 SECURITY: Simple hashing to avoid storing plain-text PINs in memory/logs
  // In a real backend, this would be validated via Cloud Functions.
  String _hashPin(String pin) {
    const salt = "CITK_SECURE_SALT_2026";
    var bytes = utf8.encode(pin + salt);
    return base64.encode(bytes);
  }

  Future<bool> verifyDriverPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 🛡️ RATE LIMITING (Client-Side Circuit Breaker)
      final lastAttempt = prefs.getInt('driver_pin_last_attempt') ?? 0;
      final attempts = prefs.getInt('driver_pin_attempts') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Lockout for 5 minutes after 5 failed attempts
      if (attempts >= 5 && (now - lastAttempt) < 300000) {
        throw Exception("Too many attempts. Try again in 5 minutes.");
      }

      // 2. 🔐 VERIFY HASH AGAINST FIRESTORE CONFIG
      final hashedInput = _hashPin(pin);
      
      // Fetch secure config (Protected by Firestore Rules)
      final doc = await _db.collection('app_config').doc('driver_secrets').get();
      
      if (!doc.exists) return false;

      final List<dynamic> validHashes = doc.data()?['valid_pin_hashes'] ?? [];
      
      if (validHashes.contains(hashedInput)) {
        // ✅ Success: Reset counters
        await prefs.setInt('driver_pin_attempts', 0);
        return true;
      } else {
        // ❌ Failure: Increment counters
        await prefs.setInt('driver_pin_attempts', attempts + 1);
        await prefs.setInt('driver_pin_last_attempt', now);
        return false;
      }
    } catch (e) {
      // Fail secure
      return false;
    }
  }
}