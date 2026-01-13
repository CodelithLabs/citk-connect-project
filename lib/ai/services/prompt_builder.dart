import 'package:intl/intl.dart';
import '../../domain/entities/academic_context.dart';

class PromptBuilder {
  static String buildSystemPrompt(AcademicContext context) {
    final sb = StringBuffer();

    // USAGE: This uses the intl package, fixing the "unused import" warning
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    sb.writeln('You are an academic assistant.');
    sb.writeln('Current Date/Time: $nowStr');
    sb.writeln('Current Context:');
    sb.writeln('- Department: ${context.department ?? "Unknown"}');
    sb.writeln('- Semester: ${context.semester ?? "Unknown"}');

    // FIX: Accessing properties directly on the object
    if (context.currentClass != null) {
      sb.writeln(
          '- Current Class: ${context.currentClass!.subjectName} in ${context.currentClass!.room}');
    } else {
      sb.writeln('- Current Class: None');
    }

    if (context.nextClass != null) {
      sb.writeln(
          '- Next Class: ${context.nextClass!.subjectName} at ${context.nextClass!.startTime}');
    }

    // Attendance Logic
    if (context.atRiskSubjects.isNotEmpty) {
      sb.writeln(
          'WARNING: The student is at risk in: ${context.atRiskSubjects.join(", ")}');
    }

    return sb.toString();
  }
}
