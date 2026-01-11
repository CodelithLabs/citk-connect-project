import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚜 FIRESTORE SEEDER
/// Run this to populate the database with initial data.
/// Usage: await FirestoreSeeder.seedFleet();
class FirestoreSeeder {
  static const String _collection = 'fleet';

  /// Seeds the 'fleet' collection with default vehicles.
  /// ⚠️ WARNING: Overwrites existing data for these IDs.
  static Future<void> seedFleet() async {
    final firestore = FirebaseFirestore.instance;

    final List<Map<String, dynamic>> fleetData = [
      {
        'id': 'BUS-01',
        'pin': '1234', // ⚠️ Change this in production
        'plateNumber': 'AS-16-C-1234',
        'status': 'active',
        'type': 'bus',
      },
      {
        'id': 'BUS-02',
        'pin': '5678',
        'plateNumber': 'AS-16-C-5678',
        'status': 'active',
        'type': 'bus',
      },
      {
        'id': 'SHUTTLE-01',
        'pin': '9999',
        'plateNumber': 'AS-16-C-9999',
        'status': 'maintenance',
        'type': 'shuttle',
      },
    ];

    try {
      for (final vehicle in fleetData) {
        final id = vehicle['id'] as String;
        final data = Map<String, dynamic>.from(vehicle)..remove('id');

        await firestore
            .collection(_collection)
            .doc(id)
            .set(data, SetOptions(merge: true));
        developer.log('✅ Seeded vehicle: $id', name: 'SEEDER');
      }
      developer.log('🎉 Fleet collection seeded successfully!', name: 'SEEDER');
    } catch (e) {
      developer.log('❌ Error seeding fleet: $e', name: 'SEEDER');
    }
  }

  /// Seeds the 'campus_locations' collection for AR Navigation.
  static Future<void> seedCampusLocations() async {
    final firestore = FirebaseFirestore.instance;
    const String collection = 'campus_locations';

    final List<Map<String, dynamic>> locations = [
      {
        "name": "Main Building",
        "lat": 26.4705,
        "lng": 90.2705,
        "type": "academic",
        "floor": "Ground Floor",
        "description": "Administrative offices and classrooms"
      },
      {
        "name": "Central Library",
        "lat": 26.4710,
        "lng": 90.2710,
        "type": "academic",
        "floor": "1st Floor",
        "description": "Main library with digital resources"
      },
      {
        "name": "Boys Hostel",
        "lat": 26.4745,
        "lng": 90.2660,
        "type": "hostel",
        "floor": "Multiple",
        "description": "Student accommodation"
      },
      {
        "name": "Canteen",
        "lat": 26.4690,
        "lng": 90.2750,
        "type": "food",
        "floor": "Ground Floor",
        "description": "Food and beverages"
      },
      {
        "name": "Computer Lab",
        "lat": 26.4715,
        "lng": 90.2695,
        "type": "academic",
        "floor": "2nd Floor",
        "description": "Computer facilities and labs"
      },
      {
        "name": "Sports Complex",
        "lat": 26.4680,
        "lng": 90.2720,
        "type": "other",
        "floor": "Ground Floor",
        "description": "Indoor and outdoor sports facilities"
      },
    ];

    try {
      for (final loc in locations) {
        // Create a readable ID from the name (e.g., "main_building")
        final id = loc['name'].toString().toLowerCase().replaceAll(' ', '_');

        await firestore
            .collection(collection)
            .doc(id)
            .set(loc, SetOptions(merge: true));
        developer.log('✅ Seeded location: ${loc['name']}', name: 'SEEDER');
      }
      developer.log('🎉 Campus locations seeded successfully!', name: 'SEEDER');
    } catch (e) {
      developer.log('❌ Error seeding locations: $e', name: 'SEEDER');
    }
  }

  /// Seeds the 'notices' collection with sample data.
  static Future<void> seedNotices() async {
    final firestore = FirebaseFirestore.instance;
    const String collection = 'notices';

    final List<Map<String, dynamic>> notices = [
      {
        'title': 'End Semester Exams Schedule',
        'body': 'The end semester examinations for B.Tech and Diploma students will commence from 15th May 2025. Detailed routine is attached.',
        'category': 'Exams',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isPinned': true,
        'postedBy': 'Controller of Examinations',
      },
      {
        'title': 'Holi Holiday Notice',
        'body': 'The institute will remain closed on 25th March 2025 on account of Holi.',
        'category': 'Holidays',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isPinned': false,
        'postedBy': 'Registrar',
      },
      {
        'title': 'Tech Fest 2025 Registration',
        'body': 'Registration for the annual Tech Fest "TechXetra" is now open. Visit the student affairs block for more details.',
        'category': 'Events',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isPinned': true,
        'postedBy': 'Student Affairs',
      },
      {
        'title': 'Library Books Return',
        'body': 'All students are requested to return borrowed books before the semester break.',
        'category': 'Urgent',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'isPinned': false,
        'postedBy': 'Librarian',
      },
    ];

    try {
      for (final notice in notices) {
        await firestore.collection(collection).add(notice);
        developer.log('✅ Seeded notice: ${notice['title']}', name: 'SEEDER');
      }
      developer.log('🎉 Notices seeded successfully!', name: 'SEEDER');
    } catch (e) {
      developer.log('❌ Error seeding notices: $e', name: 'SEEDER');
    }
  }
}
