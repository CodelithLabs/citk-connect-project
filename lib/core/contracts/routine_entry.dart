class RoutineEntry {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String subject;
  final String day;
  final String startTime;
  final String endTime;
  final String time; // Combined time string
  final String? room;
  final String? teacher;
  final String? instructor;

  RoutineEntry({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacher,
  })  : subject = subjectName,
        time = '$startTime - $endTime',
        instructor = teacher;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'subject': subject,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'time': time,
        'room': room,
        'teacher': teacher,
        'instructor': instructor,
      };

  factory RoutineEntry.fromJson(Map<String, dynamic> json) {
    return RoutineEntry(
      id: json['id'] as String,
      subjectCode: json['subjectCode'] as String,
      subjectName: json['subjectName'] as String,
      day: json['day'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
    );
  }
}
