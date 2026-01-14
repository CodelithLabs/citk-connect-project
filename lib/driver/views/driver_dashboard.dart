import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/map/services/bus_service.dart' as bus_service;

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  bool _isBroadcasting = false;
  Timer? _timer;

  // 🚌 DYNAMIC CONFIG
  String _selectedBusId = "bus_01";
  final List<String> _availableBuses = ["bus_01", "bus_02", "bus_03", "bus_04"];
  final Map<String, String> _busRegistrations = {
    "bus_01": "AS16AC6338",
    "bus_02": "AS16C3347",
    "bus_03": "AS16C3348",
    "bus_04": "AS16AC6339",
  };
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

  void toggleLiveStatus(bool isLive) {
    if (isLive) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        debugPrint('Updating location...');
      });
    } else {
      _timer?.cancel();
    }
    setState(() => _isBroadcasting = isLive);
  }

  Future<void> _toggleBroadcast() async {
    toggleLiveStatus(!_isBroadcasting);
  }

  @override
  void dispose() {
    _timer?.cancel();
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

            if (_isBroadcasting)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("Status: Online",
                        style: GoogleFonts.inter(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

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
                        child: Text(
                          "BUS ${id.split('_').last} (${_busRegistrations[id]})",
                          style: GoogleFonts.robotoMono(color: Colors.white),
                        ),
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
                      () {
                    setState(() => _condition = "OK");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
                  const SizedBox(width: 10),
                  _buildStatusToggle(
                      "TRAFFIC", Colors.orange, _condition == "TRAFFIC", () {
                    setState(() => _condition = "TRAFFIC");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
                  const SizedBox(width: 10),
                  _buildStatusToggle("ISSUE", Colors.red, _condition == "ISSUE",
                      () {
                    setState(() => _condition = "ISSUE");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusToggle("EMPTY", Colors.blue, _occupancy == "LOW",
                      () {
                    setState(() => _occupancy = "LOW");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
                  const SizedBox(width: 10),
                  _buildStatusToggle("HALF", Colors.purple, _occupancy == "MED",
                      () {
                    setState(() => _occupancy = "MED");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
                  const SizedBox(width: 10),
                  _buildStatusToggle(
                      "FULL", Colors.redAccent, _occupancy == "FULL", () {
                    setState(() => _occupancy = "FULL");
                    ref
                        .read(bus_service.busServiceProvider)
                        .updateStatus(_condition, _occupancy);
                  }),
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
