import 'dart:async';
import 'dart:ui';
import 'package:citk_connect/map/models/bus_data.dart';
import 'package:citk_connect/map/services/bus_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

// Helper Provider to stream a specific bus
final busStreamProvider = StreamProvider.family<BusData, String>((ref, busId) {
  final service = ref.watch(busServiceProvider);
  return service.streamBus(busId);
});

class BusTrackerScreen extends ConsumerStatefulWidget {
  const BusTrackerScreen({super.key});

  @override
  ConsumerState<BusTrackerScreen> createState() => _BusTrackerScreenState();
}

class _BusTrackerScreenState extends ConsumerState<BusTrackerScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  late AnimationController _animController;

  // 🎥 Interpolation State
  Set<Polyline> _polylines = {};
  BusData? _currentBusData;
  BusData? _prevBusData;
  double _lat = 0, _lng = 0, _heading = 0;
  bool _isAutoFollow = true; // 🎥 Auto-follow state

  //  CIT Kokrajhar Coordinates
  static const CameraPosition _kCitCampus = CameraPosition(
    target: LatLng(26.4700, 90.2700),
    zoom: 14.4746,
  );

  // 🌑 Cyberpunk Map Style JSON
  static const String _darkMapStyle = '''
    [
      { "elementType": "geometry", "stylers": [{ "color": "#242f3e" }] },
      { "elementType": "labels.text.stroke", "stylers": [{ "color": "#242f3e" }] },
      { "elementType": "labels.text.fill", "stylers": [{ "color": "#746855" }] },
      { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#d59563" }] },
      { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{ "color": "#d59563" }] },
      { "featureType": "poi.park", "elementType": "geometry", "stylers": [{ "color": "#263c3f" }] },
      { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{ "color": "#6b9a76" }] },
      { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#38414e" }] },
      { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#212a37" }] },
      { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{ "color": "#9ca5b3" }] },
      { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#746855" }] },
      { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{ "color": "#1f2835" }] },
      { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{ "color": "#f3d19c" }] },
      { "featureType": "transit", "elementType": "geometry", "stylers": [{ "color": "#2f3948" }] },
      { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{ "color": "#d59563" }] },
      { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#17263c" }] },
      { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#515c6d" }] },
      { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [{ "color": "#17263c" }] }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    // 🎬 Animation Controller for smooth movement (2 seconds to match update rate)
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..addListener(() {
        if (_prevBusData != null && _currentBusData != null) {
          setState(() {
            final t = _animController.value;
            _lat = lerpDouble(_prevBusData!.lat, _currentBusData!.lat, t) ??
                _currentBusData!.lat;
            _lng = lerpDouble(_prevBusData!.lng, _currentBusData!.lng, t) ??
                _currentBusData!.lng;

            // 🔄 Smart Rotation (Shortest Path)
            double start = _prevBusData!.heading;
            double end = _currentBusData!.heading;
            double diff = end - start;
            if (diff > 180) diff -= 360;
            if (diff < -180) diff += 360;
            _heading = start + (diff * t);
          });
        }
      });
    _loadRoute();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final service = ref.read(busServiceProvider);
    // Fetch route points (Hardcoded 'bus_01' for demo)
    final routePoints = await service.getRoute('bus_01');

    final latLngs =
        routePoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_01'),
            points: latLngs,
            color: const Color(0xFF6C63FF), // Gen Z Periwinkle
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎧 Listening to 'bus_01' (Hardcoded for demo)
    final busAsync = ref.watch(busStreamProvider('bus_01'));

    // ⚡ Trigger Animation when new data arrives
    ref.listen(busStreamProvider('bus_01'), (prev, next) {
      next.whenData((newData) {
        setState(() {
          if (_currentBusData == null) {
            _lat = newData.lat;
            _lng = newData.lng;
            _heading = newData.heading;
          } else {
            // Start animation from CURRENT visual position to avoid jumps
            _prevBusData = BusData(
                id: newData.id,
                lat: _lat,
                lng: _lng,
                heading: _heading,
                speed: newData.speed,
                condition: newData.condition,
                occupancy: newData.occupancy);
            _animController.forward(from: 0.0);
          }
          _currentBusData = newData;
        });

        if (_isAutoFollow) {
          _moveCamera(newData.lat, newData.lng);
        }
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ Google Map Layer
          Listener(
            onPointerDown: (_) {
              // 🛑 User touched map -> Stop auto-following
              if (_isAutoFollow) setState(() => _isAutoFollow = false);
            },
            child: GoogleMap(
              initialCameraPosition: _kCitCampus,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                controller.setMapStyle(_darkMapStyle);
              },
              markers: _currentBusData != null
                  ? {
                      _createBusMarker(BusData(
                          id: _currentBusData!.id,
                          lat: _lat,
                          lng: _lng,
                          heading: _heading,
                          speed: _currentBusData!.speed,
                          condition: _currentBusData!.condition,
                          occupancy: _currentBusData!.occupancy))
                    }
                  : {},
              polylines: _polylines,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),

          // 🔙 Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF181B21),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // 🎯 Recenter Button (Only shows when auto-follow is OFF)
          if (!_isAutoFollow)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() => _isAutoFollow = true);
                  if (_currentBusData != null) {
                    _moveCamera(_currentBusData!.lat, _currentBusData!.lng);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.gps_fixed, color: Colors.white),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ),

          // 🚦 Bus Status Card (The Answer to your Request)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: busAsync.when(
              data: (bus) => BusInfoCard(bus: bus),
              loading: () => const SizedBox.shrink(), // Don't show until loaded
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCamera(double lat, double lng) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  Marker _createBusMarker(BusData bus) {
    return Marker(
      markerId: MarkerId(bus.id),
      position: LatLng(bus.lat, bus.lng),
      rotation: bus.heading,
      // In a real app, use BitmapDescriptor.fromAssetImage for a custom bus icon
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  // REMOVED: _buildBusInfoCard, _showReportDialog, _buildReportOption
  // These are now part of the BusInfoCard class below to prevent rebuilds.
}

class BusInfoCard extends ConsumerWidget {
  final BusData bus;

  const BusInfoCard({super.key, required this.bus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 Logic to determine color based on traffic
    Color statusColor;
    String statusText;

    switch (bus.condition) {
      case 'HIGH':
        statusColor = const Color(0xFFFF5252);
        statusText = 'Heavy Traffic';
        break;
      case 'MED':
        statusColor = Colors.orangeAccent;
        statusText = 'Moderate Traffic';
        break;
      case 'LOW':
      default:
        statusColor = const Color(0xFF00E676);
        statusText = 'Clear Road';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181B21).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus No. 1',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Arriving in ~5 mins', // Mock ETA
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              //  Speedometer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(bus.speed * 3.6).toStringAsFixed(0)} km/h', // m/s to km/h
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 🚦 Traffic & Occupancy Indicators
          Row(
            children: [
              _StatusBadge(
                  label: statusText, color: statusColor, icon: Icons.traffic),
              const SizedBox(width: 12),
              _StatusBadge(
                  label: 'Occupancy: ${bus.occupancy}',
                  color: Colors.blueAccent,
                  icon: Icons.people),
            ],
          ),
          const SizedBox(height: 16),
          // 📤 Share & ⚠️ Report Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                        'Hey! Bus No. 1 is arriving at CIT Kokrajhar in ~5 mins. Track it on CITK Connect! 🚌💨');
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF6C63FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportDialog(context, ref, bus.id),
                  icon: const Icon(Icons.report_problem, size: 16),
                  label: const Text('Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF5252).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFFFF5252),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, curve: Curves.easeOut);
  }

  void _showReportDialog(BuildContext context, WidgetRef ref, String busId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF181B21),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPORT ISSUE',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF5252),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What is wrong with this bus?',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildReportOption(context, ref, busId, 'Breakdown', Icons.build),
              _buildReportOption(
                  context, ref, busId, 'Accident', Icons.medical_services),
              _buildReportOption(
                  context, ref, busId, 'Heavy Delay', Icons.timer_off),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(BuildContext context, WidgetRef ref, String busId,
      String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: GoogleFonts.inter(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ref.read(busServiceProvider).reportIssue(busId, label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reported: $label. Admin notified.'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
