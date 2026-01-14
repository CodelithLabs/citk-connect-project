import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/map/models/bus_data.dart';
import 'package:geolocator/geolocator.dart';

/// Provides an instance of [BusService] to the app.
///
/// This service is responsible for handling all business logic related to the bus,
/// including broadcasting location updates to Firestore.
final busServiceProvider = Provider((ref) => BusService());

/// A service class to manage bus-related operations.
///
/// This includes broadcasting the bus's location, speed, occupancy, and status
/// to the Firestore database. It is designed to be used by the driver's dashboard.
class BusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;
  String _currentCondition = "OK";
  String _currentOccupancy = "LOW";

  /// Broadcasts the current location and status of a bus to Firestore.
  ///
  /// - [busId]: The unique identifier for the bus (e.g., "bus_01").
  /// - [lat]: The current latitude of the bus.
  /// - [lng]: The current longitude of the bus.
  /// - [heading]: The direction the bus is traveling in degrees.
  /// - [speed]: The current speed of the bus in meters per second.
  /// - [condition]: The current traffic condition (e.g., "OK", "TRAFFIC").
  /// - [occupancy]: The current passenger occupancy level (e.g., "LOW", "MED", "FULL").
  ///
  /// This method updates the document for the given `busId` in the `bus_locations`
  /// collection. If the document does not exist, it will be created.
  ///
  /// Throws [FirebaseException] if write fails (allows caller to handle).
  Future<void> broadcastLocation(
    String busId,
    double lat,
    double lng,
    double heading,
    double speed,
    String condition,
    String occupancy,
  ) async {
    try {
      // Validate inputs
      if (busId.isEmpty) {
        throw ArgumentError('busId cannot be empty');
      }

      // Reference to the specific bus document in the 'bus_locations' collection
      final docRef = _firestore.collection('bus_locations').doc(busId);

      // Set the data for the bus location. This will create the document if it
      // doesn't exist, or overwrite it if it does.
      await docRef.set({
        'id': busId,
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        'condition': condition, // e.g., "OK", "TRAFFIC", "ISSUE"
        'occupancy': occupancy, // e.g., "LOW", "MED", "FULL"
        'timestamp':
            FieldValue.serverTimestamp(), // Use server time for consistency
      });

      developer.log(
        'Location broadcast successful for bus $busId',
        name: 'BusService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error broadcasting location for bus $busId',
        error: e,
        stackTrace: stackTrace,
        name: 'BusService',
        level: 2000, // WARNING level
      );
      FirebaseCrashlytics.instance.recordError(e, stackTrace,
          reason: 'Broadcast Location Failed for $busId', fatal: false);
      rethrow; // Allow caller to handle the error
    }
  }

  /// Starts broadcasting location updates.
  Future<void> startBroadcasting({
    required String busId,
    required String routeName,
    required String condition,
    required String occupancy,
  }) async {
    _currentCondition = condition;
    _currentOccupancy = occupancy;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Stop existing stream if any
    await _positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      broadcastLocation(
        busId,
        position.latitude,
        position.longitude,
        position.heading,
        position.speed,
        _currentCondition,
        _currentOccupancy,
      );
    }, onError: (e) {
      developer.log('GPS Stream Error', error: e);
    });
  }

  /// Stops broadcasting.
  Future<void> stopBroadcasting(String busId) async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// Updates status flags for the next broadcast.
  void updateStatus(String condition, String occupancy) {
    _currentCondition = condition;
    _currentOccupancy = occupancy;
  }

  Stream<BusData> streamBus(String busId) {
    return _firestore
        .collection('bus_locations')
        .doc(busId)
        .snapshots()
        .map((snapshot) => BusData.fromFirestore(snapshot));
  }

  Future<List<Map<String, double>>> getRoute(String busId) async {
    // In a real app, this would fetch from Firestore or a remote config
    // For now, return a hardcoded route based on busId
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
    if (busId == 'bus_01' || busId == 'bus_03') {
      // Route from Kokrajhar town to CIT
      return [
        {'lat': 26.4050, 'lng': 90.2700}, // Kokrajhar Railway Station
        {'lat': 26.4150, 'lng': 90.2750}, // JD Road
        {'lat': 26.4300, 'lng': 90.2780}, // Balagaon
        {'lat': 26.4500, 'lng': 90.2750}, // Bodoland University
        {'lat': 26.4700, 'lng': 90.2700}, // CIT Campus Gate
        {'lat': 26.4750, 'lng': 90.2650}, // Academic Complex
      ];
    } else {
      // Default route (Bus 2 and 4), maybe from a different location
      return [
        {'lat': 26.4862, 'lng': 90.2582}, // Alt Start Point
        {'lat': 26.4800, 'lng': 90.2650},
        {'lat': 26.4700, 'lng': 90.2700}, // CIT Campus Gate
        {'lat': 26.4750, 'lng': 90.2650}, // Academic Complex
      ];
    }
  }

  /// Reports an issue with a specific bus.
  Future<void> reportIssue(String busId, String issue) async {
    try {
      await _firestore.collection('bus_reports').add({
        'busId': busId,
        'issue': issue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reporting issue: $e');
    }
  }
}
