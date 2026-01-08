import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citk_connect/map/models/bus_data.dart';

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
  /// TODO: Implement more robust error handling, such as using a logger service
  /// or reporting errors to a crash reporting tool instead of just printing to the console.
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
    } catch (e) {
      // Basic error handling. Prints the error to the console.
      // This should be replaced with a more sophisticated logging solution.
      print('Error broadcasting location for bus $busId: $e');
    }
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
