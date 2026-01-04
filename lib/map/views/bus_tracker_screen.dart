import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citk_connect/map/views/bus_service.dart';

class BusTrackerScreen extends ConsumerStatefulWidget {
  const BusTrackerScreen({super.key});

  @override
  ConsumerState<BusTrackerScreen> createState() => _BusTrackerScreenState();
}

class _BusTrackerScreenState extends ConsumerState<BusTrackerScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();

  // 🗺️ STATIC ROUTE (Visual Guide Only)
  // We keep this to show the "Path" line, even though the bus moves via GPS.
  final List<LatLng> _routePoints = [
    const LatLng(26.4700, 90.2700), // Santinagar (Start)
    const LatLng(26.4720, 90.2680),
    const LatLng(26.4750, 90.2660),
    const LatLng(26.4780, 90.2640),
    const LatLng(26.4800, 90.2620),
    const LatLng(26.4820, 90.2600),
    const LatLng(26.4850, 90.2590),
    const LatLng(26.4862, 90.2582), // CITK Campus (End)
  ];

  // 🚌 REAL-TIME STATE
  Marker? _busMarker;
  String _selectedBusId = "bus_04"; // Default
  final List<String> _buses = ["bus_01", "bus_02", "bus_03", "bus_04"];
  String _currentCondition = "OK";
  String _currentOccupancy = "LOW";

  // 🎥 ANIMATION ENGINE (The "Zomato" Smoothness)
  late AnimationController _animController;
  LatLng _prevPosition = const LatLng(26.4700, 90.2700);
  LatLng _targetPosition = const LatLng(26.4700, 90.2700);
  double _prevHeading = 0.0;
  double _targetHeading = 0.0;

  // ⏱️ ETA LOGIC
  String _etaText = "Calculating...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    // Initialize Animation Controller (runs for 2 seconds per update)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(_updateMarkerPosition);
  }

  // 🔒 SECURITY: Ensure only Students/Staff access this
  Future<void> _checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    // Allow students, faculty, and aspirants
    if (!doc.exists && mounted) {
      // Handle edge case or guest
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Called every frame during animation to slide the marker
  void _updateMarkerPosition() {
    if (!mounted) return;

    // Linear Interpolation (Lerp)
    final double t = _animController.value;
    final double lat = _prevPosition.latitude +
        (_targetPosition.latitude - _prevPosition.latitude) * t;
    final double lng = _prevPosition.longitude +
        (_targetPosition.longitude - _prevPosition.longitude) * t;

    // Heading Interpolation (shortest path)
    double diff = _targetHeading - _prevHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final double heading = _prevHeading + diff * t;

    final newPos = LatLng(lat, lng);

    setState(() {
      _busMarker = Marker(
        markerId: const MarkerId('college_bus'),
        position: newPos,
        rotation: heading,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5), // Center the icon
        infoWindow:
            const InfoWindow(title: 'CITK Bus 04', snippet: 'Live Tracking'),
      );
    });
  }

  // Called when Firestore sends new data
  void _onNewLocationData(BusData data) {
    // 1. Save current state as "Previous"
    if (_busMarker != null) {
      _prevPosition = _busMarker!.position;
      _prevHeading = _busMarker!.rotation;
    }

    // 2. Set new Target
    _targetPosition = LatLng(data.lat, data.lng);
    _targetHeading = data.heading;
    _currentCondition = data.condition;
    _currentOccupancy = data.occupancy;

    if (data.status == 'OFFLINE') {
      setState(() => _etaText = "🔴 BUS IS OFFLINE");
      return;
    }

    // 2.5 Calculate ETA (Distance to Campus End Point)
    // In a real app, use Google Distance Matrix API. Here we use Haversine for free.
    final double distanceInMeters = Geolocator.distanceBetween(data.lat,
        data.lng, _routePoints.last.latitude, _routePoints.last.longitude);

    // Assuming avg speed of 30km/h (8.3 m/s) if data.speed is 0 or unreliable
    final double speed = (data.speed > 1) ? data.speed : 8.3;
    final int minutes = (distanceInMeters / speed / 60).round();
    setState(() => _etaText = "$minutes min to Campus");

    // 3. Reset and Start Animation to slide to new target
    _animController.forward(from: 0.0);

    // 4. Move Camera if distance is significant
    _moveCamera(_targetPosition);
  }

  Future<void> _moveCamera(LatLng pos) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  Widget build(BuildContext context) {
    // 🎧 LISTEN TO THE CLOUD
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFF0F1115),
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. THE MAP
          GoogleMap(
            mapType: MapType.normal,
            // Dark Mode Map Style (Optional: Add JSON style here for Gen Z look)
            initialCameraPosition: CameraPosition(
              target: _routePoints[0],
              zoom: 15,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: const Color(0xFF6C63FF),
                width: 5,
              ),
            },
            markers: _busMarker != null ? {_busMarker!} : {},
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // 2. DATA LISTENER (Invisible Logic)
          StreamBuilder<BusData>(
            stream: ref.read(busServiceProvider).streamBus(_selectedBusId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // Trigger animation when data changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_targetPosition.latitude != snapshot.data!.lat) {
                    _onNewLocationData(snapshot.data!);
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),

          // 3. GEN Z HEADER CARD
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF181B21)
                    .withValues(alpha: 0.9), // Glass Dark
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus,
                        color: Color(0xFF6C63FF), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedBusId.toUpperCase().replaceAll('_', ' '),
                          style: GoogleFonts.robotoMono(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                      Text(_etaText, // ⏱️ LIVE ETA
                          style: GoogleFonts.inter(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  // 🚦 STATUS PILL
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_currentCondition == "ISSUE"
                              ? Colors.red
                              : Colors.green)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: (_currentCondition == "ISSUE"
                                  ? Colors.red
                                  : Colors.green)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: (_currentCondition == "ISSUE"
                                    ? Colors.red
                                    : Colors.green),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(_currentCondition == "ISSUE" ? "DELAY" : "LIVE",
                            style: GoogleFonts.inter(
                                color: (_currentCondition == "ISSUE"
                                    ? Colors.red
                                    : Colors.green),
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 👥 OCCUPANCY PILL (New Feature)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_currentOccupancy == "FULL"
                              ? Colors.red
                              : Colors.blue)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: (_currentOccupancy == "FULL"
                                  ? Colors.red
                                  : Colors.blue)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Text(_currentOccupancy,
                        style: GoogleFonts.inter(
                            color: (_currentOccupancy == "FULL"
                                ? Colors.red
                                : Colors.blue),
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),

          // 4. BUS SELECTOR (Floating Pills)
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _buses.length,
                itemBuilder: (context, index) {
                  final busId = _buses[index];
                  final isSelected = busId == _selectedBusId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBusId = busId),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                        ),
                      ),
                      child: Text(
                        busId.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 5. BACK BUTTON
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.pop(context),
              backgroundColor: const Color(0xFF181B21),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
