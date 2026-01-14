// lib/ai/bus_schedule_data.dart

Map<String, dynamic> getBusScheduleData() {
  return {
    "meta": {
      "institution": "Central Institute of Technology Kokrajhar",
      "effective_from": "2025-10-21"
    },
    "weekdays": {
      "morning": {
        "cit_to_town": ["07:20", "08:20"],
        "town_to_cit": ["07:50", "08:50"]
      },
      "afternoon": {
        "cit_to_town": ["13:30"],
        "town_to_cit": []
      },
      "evening": {
        "cit_to_town": ["16:45", "17:45"],
        "town_to_cit": ["17:15", "18:30"]
      }
    },
    "weekends": {
      "morning": {
        "cit_to_town": ["09:30"],
        "town_to_cit": []
      },
      "afternoon": {
        "cit_to_town": ["14:30"],
        "town_to_cit": ["12:30"]
      },
      "evening": {
        "cit_to_town": [],
        "town_to_cit": ["17:30"]
      }
    }
  };
}
