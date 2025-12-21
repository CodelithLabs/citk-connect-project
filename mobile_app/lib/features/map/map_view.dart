import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();

  // Coordinates for CIT Kokrajhar
  static const LatLng _citKokrajhar = LatLng(26.4795, 90.2673);

  // Set of markers for the map
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('main_gate'),
      position: LatLng(26.4780, 90.2675), // Adjusted coordinates
      infoWindow: InfoWindow(title: 'Main Gate'),
    ),
    const Marker(
      markerId: MarkerId('admin_block'),
      position: LatLng(26.4800, 90.2665), // Adjusted coordinates
      infoWindow: InfoWindow(title: 'Administrative Block'),
    ),
    const Marker(
      markerId: MarkerId('boys_hostel'),
      position: LatLng(26.4815, 90.2685), // Adjusted coordinates
      infoWindow: InfoWindow(title: 'Boys\' Hostel'),
    ),
     const Marker(
      markerId: MarkerId('girls_hostel'),
      position: LatLng(26.4790, 90.2690), // Adjusted coordinates
      infoWindow: InfoWindow(title: 'Girls\' Hostel'),
    ),
    const Marker(
      markerId: MarkerId('central_library'),
      position: LatLng(26.4805, 90.2655), // Adjusted coordinates
      infoWindow: InfoWindow(title: 'Central Library'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigator'),
        centerTitle: true,
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: const CameraPosition(
          target: _citKokrajhar,
          zoom: 16,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        myLocationEnabled: true, // Shows the blue dot for user location
        myLocationButtonEnabled: false, // We use a custom FAB
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCurrentUserLocation,
        label: const Text('My Location'),
        icon: const Icon(Icons.my_location),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _goToCurrentUserLocation() async {
    try {
      Position position = await _determinePosition();
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17.5, // Zoom in closer on user location
        ),
      ));
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  /// Determine the current position of the device.
  Future<Position> _determinePosition() async {
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

    return await Geolocator.getCurrentPosition();
  }
}
