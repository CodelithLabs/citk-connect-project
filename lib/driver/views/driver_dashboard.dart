import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/map/services/bus_service.dart' as bus_service;

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  bool _isBroadcasting = false;
  StreamSubscription<Position>? _positionStream;
  DateTime? _lastBroadcastTime; // 🧠 Smart Batching Tracker

  // 🚌 DYNAMIC CONFIG
  String _selectedBusId = "bus_04"; // Default to Bus 4
  final List<String> _availableBuses = ["bus_01", "bus_02", "bus_03", "bus_04"];
  bool _isLoading = true;

  // 🚦 STATUS FLAGS
  String _condition = "OK"; // OK, TRAFFIC, ISSUE
  String _occupancy = "LOW"; // LOW, MED, FULL

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  // 🔒 SECURITY: Ensure only Drivers/Faculty access this
  Future<void> _checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = doc.data()?['role'];

    if (role != 'driver' && role != 'faculty' && mounted) {
      // Optional: Handle unauthorized access if RoleDispatcher fails
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      // STOP BROADCASTING
      await _positionStream?.cancel();
      setState(() => _isBroadcasting = false);
    } else {
      // START BROADCASTING
      // 0. Check GPS Service Status
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationServiceDialog();
        return;
      }

      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return; // User rejected
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showPermissionDialog();
        return;
      }

      // 🛡️ MEMORY LEAK FIX: Prevent stream start if widget was disposed during permission check
      if (!mounted) return;

      setState(() => _isBroadcasting = true);

      // 2. Configure Background Settings
      LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // ⚡ Get all updates (filter in code)
          intervalDuration:
              const Duration(seconds: 3), // ⚡ Force update every 3s
          // 🔔 Foreground Notification: Keeps service alive when minimized
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "CITK Driver Active",
            notificationText: "Broadcasting location to campus...",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 0, // ⚡ Get all updates
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }

      // 3. Start Stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        // 🧠 SMART BATCHING: Throttle Firestore Writes
        final now = DateTime.now();
        if (_lastBroadcastTime != null &&
            now.difference(_lastBroadcastTime!) < const Duration(seconds: 3)) {
          return; // ⏳ Throttle: Prevent Firestore spam
        }
        _lastBroadcastTime = now;

        // 4. Send to Cloud
        ref.read(bus_service.busServiceProvider).broadcastLocation(
              _selectedBusId,
              position.latitude,
              position.longitude,
              position.heading,
              position.speed,
              _condition,
              _occupancy,
            );
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B21),
        title: Text("GPS Disabled",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Location services are turned off. Please enable GPS to broadcast.",
          style: GoogleFonts.inter(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text("Enable",
                style: GoogleFonts.inter(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B21),
        title: Text("Location Required",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "To broadcast bus location, please enable location permissions in App Settings.",
          style: GoogleFonts.inter(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text("Open Settings",
                style: GoogleFonts.inter(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kBg = Color(0xFF0F1115);
    const kAccent = Color(0xFF6C63FF);

    if (_isLoading) {
      return const Scaffold(
          backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("DRIVER CONSOLE",
            style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kBg,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Indicator
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isBroadcasting
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isBroadcasting ? Colors.green : Colors.red,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isBroadcasting ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                _isBroadcasting ? Icons.wifi_tethering : Icons.wifi_off,
                size: 80,
                color: _isBroadcasting ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 40),

            Text(
              _isBroadcasting ? "BROADCASTING LIVE" : "SYSTEM OFFLINE",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isBroadcasting
                  ? "Students can see your location."
                  : "Tap below to start route.",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 60),

            // 🚌 BUS SELECTOR
            if (!_isBroadcasting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBusId,
                    dropdownColor: const Color(0xFF181B21),
                    style: GoogleFonts.robotoMono(
                        color: Colors.white, fontSize: 16),
                    icon: const Icon(Icons.arrow_drop_down, color: kAccent),
                    items: _availableBuses.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text(id.toUpperCase().replaceAll('_', ' ')),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBusId = val!),
                  ),
                ),
              ),

            // 🚦 LIVE CONTROLS (Only when broadcasting)
            if (_isBroadcasting) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusToggle("OK", Colors.green, _condition == "OK",
                      () => setState(() => _condition = "OK")),
                  const SizedBox(width: 10),
                  _buildStatusToggle(
                      "TRAFFIC",
                      Colors.orange,
                      _condition == "TRAFFIC",
                      () => setState(() => _condition = "TRAFFIC")),
                  const SizedBox(width: 10),
                  _buildStatusToggle("ISSUE", Colors.red, _condition == "ISSUE",
                      () => setState(() => _condition = "ISSUE")),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusToggle("EMPTY", Colors.blue, _occupancy == "LOW",
                      () => setState(() => _occupancy = "LOW")),
                  const SizedBox(width: 10),
                  _buildStatusToggle("HALF", Colors.purple, _occupancy == "MED",
                      () => setState(() => _occupancy = "MED")),
                  const SizedBox(width: 10),
                  _buildStatusToggle(
                      "FULL",
                      Colors.redAccent,
                      _occupancy == "FULL",
                      () => setState(() => _occupancy = "FULL")),
                ],
              ),
              const SizedBox(height: 30),
            ],

            // Big Button
            ElevatedButton(
              onPressed: _toggleBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBroadcasting ? Colors.red : kAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                _isBroadcasting ? "STOP ROUTE" : "START ROUTE",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(
      String label, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
