import 'package:cloud_firestore/cloud_firestore.dart';

class BusData {
  final String id;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final String condition; // Traffic: LOW, MED, HIGH
  final String occupancy; // LOW, MED, FULL

  BusData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speed,
    required this.condition,
    required this.occupancy,
  });

  factory BusData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return BusData(
      id: data?['id'] ?? 'unknown',
      lat: (data?['lat'] ?? 0.0).toDouble(),
      lng: (data?['lng'] ?? 0.0).toDouble(),
      heading: (data?['heading'] ?? 0.0).toDouble(),
      speed: (data?['speed'] ?? 0.0).toDouble(),
      condition: data?['condition'] ?? 'LOW',
      occupancy: data?['occupancy'] ?? 'LOW',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BusData &&
        other.id == id &&
        other.lat == lat &&
        other.lng == lng &&
        other.heading == heading &&
        other.speed == speed &&
        other.condition == condition &&
        other.occupancy == occupancy;
  }

  @override
  int get hashCode =>
      Object.hash(id, lat, lng, heading, speed, condition, occupancy);
}
