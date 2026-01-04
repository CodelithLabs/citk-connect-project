import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🚌 BUS DATA MODEL
class BusData {
  final String id;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final String status; // 'MOVING', 'STOPPED', 'OFFLINE'
  final String condition; // 'OK', 'TRAFFIC', 'ISSUE'
  final String occupancy; // 'LOW', 'MED', 'FULL'
  final DateTime lastUpdated;

  BusData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.status,
    required this.condition,
    required this.occupancy,
    required this.lastUpdated,
  });

  factory BusData.fromMap(Map<String, dynamic> map, String id) {
    return BusData(
      id: id,
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
      heading: (map['heading'] ?? 0.0).toDouble(),
      speed: (map['speed'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'OFFLINE',
      condition: map['condition'] ?? 'OK',
      occupancy: map['occupancy'] ?? 'LOW',
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final busServiceProvider = Provider((ref) => BusService());

class BusService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📡 DRIVER: Broadcast Location to Cloud
  Future<void> broadcastLocation(String busId, double lat, double lng,
      double heading, double speed, String condition, String occupancy) async {
    await _db.collection('buses').doc(busId).set({
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'status': speed > 1.0 ? 'MOVING' : 'STOPPED',
      'condition': condition,
      'occupancy': occupancy,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 👀 STUDENT: Listen to Real-time Stream
  Stream<BusData> streamBus(String busId) {
    return _db.collection('buses').doc(busId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        // Return default if bus hasn't started yet
        return BusData(
            id: busId,
            lat: 26.4700,
            lng: 90.2700,
            heading: 0,
            speed: 0,
            status: 'OFFLINE',
            condition: 'OK',
            occupancy: 'LOW',
            lastUpdated: DateTime.now());
      }
      return BusData.fromMap(snapshot.data()!, snapshot.id);
    });
  }
}
