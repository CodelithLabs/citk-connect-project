import 'package:cloud_firestore/cloud_firestore.dart';

class BusData {
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final String condition;
  final String occupancy;
  final String status;

  BusData({
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.condition,
    required this.occupancy,
    required this.status,
  });

  factory BusData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BusData(
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      heading: (data['heading'] ?? 0.0).toDouble(),
      speed: (data['speed'] ?? 0.0).toDouble(),
      condition: data['condition'] ?? 'UNKNOWN',
      occupancy: data['occupancy'] ?? 'UNKNOWN',
      status: data['timestamp'] != null ? 'ONLINE' : 'OFFLINE',
    );
  }
}
