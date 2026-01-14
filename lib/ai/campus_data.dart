// lib/ai/campus_data.dart

Map<String, dynamic> getLibraryData() {
  return {
    'timings': '9:00 AM - 8:00 PM',
    'location': 'Academic Block',
    'contact': 'library@cit.ac.in'
  };
}

Map<String, dynamic> getHostelsData() {
  return {
    'boys': [
      {'name': 'Dwimalu', 'capacity': 200},
      {'name': 'Jwhwlao', 'capacity': 180}
    ],
    'girls': [
      {'name': 'Gwzwon', 'capacity': 150},
      {'name': 'Nivedita', 'capacity': 120}
    ]
  };
}

List<Map<String, dynamic>> getBusesData() {
  return [
    {'id': 'bus_01', 'number': 'AS16AC6338', 'route': 'Campus ↔ Railgate'},
    {'id': 'bus_02', 'number': 'AS16C3347', 'route': 'Campus ↔ Town'},
    {'id': 'bus_03', 'number': 'AS16C3348', 'route': 'Campus ↔ Adabari'},
    {'id': 'bus_04', 'number': 'AS16AC6339', 'route': 'Campus ↔ Haltugaon'},
  ];
}
