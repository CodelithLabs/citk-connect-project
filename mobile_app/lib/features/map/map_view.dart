import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController _mapController;
  final LatLng _citKokrajhar = const LatLng(26.4795, 90.2673);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addMarkers();
  }

  void _addMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('main_gate'),
        position: const LatLng(26.4795, 90.2673), // Replace with actual coordinates
        infoWindow: const InfoWindow(title: 'Main Gate'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('admin_block'),
        position: const LatLng(26.4800, 90.2670), // Replace with actual coordinates
        infoWindow: const InfoWindow(title: 'Administrative Block'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('boys_hostel'),
        position: const LatLng(26.4780, 90.2680), // Replace with actual coordinates
        infoWindow: const InfoWindow(title: 'Boys\' Hostel'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('girls_hostel'),
        position: const LatLng(26.4810, 90.2660), // Replace with actual coordinates
        infoWindow: const InfoWindow(title: 'Girls\' Hostel'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('central_library'),
        position: const LatLng(26.4790, 90.2665), // Replace with actual coordinates
        infoWindow: const InfoWindow(title: 'Central Library'),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _centerOnUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _citKokrajhar,
          zoom: 15,
        ),
        markers: _markers,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
