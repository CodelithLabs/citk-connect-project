import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusTrackerScreen extends StatefulWidget {
  const BusTrackerScreen({super.key});

  @override
  State<BusTrackerScreen> createState() => _BusTrackerScreenState();
}

class _BusTrackerScreenState extends State<BusTrackerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // 1. The Route (Waypoints from Santinagar to CITK)
  // I created a simple path. in real app, this comes from GPS.
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

  int _currentPositionIndex = 0;
  Marker? _busMarker;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 2. Simulate Bus Movement
  void _startSimulation() {
    // Set initial marker
    _updateMarker(_routePoints[0]);

    // Move the bus every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentPositionIndex++;
        
        // Loop back to start if it reaches the end
        if (_currentPositionIndex >= _routePoints.length) {
          _currentPositionIndex = 0;
        }

        _updateMarker(_routePoints[_currentPositionIndex]);
      });
    });
  }

  void _updateMarker(LatLng position) {
    _busMarker = Marker(
      markerId: const MarkerId('college_bus'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Blue Bus
      infoWindow: const InfoWindow(title: 'CITK Bus No. 4', snippet: 'On the way'),
      rotation: 0, // In a real app, calculate bearing here
    );
    
    // Optional: Auto-follow camera
    _moveCamera(position);
  }

  Future<void> _moveCamera(LatLng pos) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _routePoints[0],
              zoom: 15,
            ),
            markers: _busMarker != null ? {_busMarker!} : {},
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          
          // Header Card
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.blueAccent, size: 30),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bus No. 4", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Next Stop: Flyover Point", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                    child: const Text("LIVE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}