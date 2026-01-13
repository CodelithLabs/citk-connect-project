class RoutineEntry {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String day;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacher;

  RoutineEntry({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacher,
  });

  // Aliases for compatibility
  String get subject => subjectName;
  String get instructor => teacher ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'teacher': teacher,
      };

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    return RoutineEntry(
      id: json['id'] as String,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      day: json['day'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
    );
  }
}
