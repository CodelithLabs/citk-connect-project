import 'package:flutter/foundation.dart';

/// 📦 THE DATA PACKET
/// This holds all the extracted identity info
class CITParsedData {
  final String role;        // 'student', 'faculty', 'aspirant', 'driver'
  final String degree;      // 'B.Tech', 'Diploma', 'M.Tech', 'PhD'
  final String branch;      // 'Computer Science', etc.
  final String department;  // 'CSE', 'ECE', etc.
  final int batch;          // 2025, 2026, etc.
  final String semester;    // '3rd Sem', 'Graduated'
  final String rollNumber;  // 'CIT/25/CSE/001'
  final bool isGraduated;

  CITParsedData({
    required this.role,
    required this.degree,
    required this.branch,
    required this.department,
    required this.batch,
    required this.semester,
    required this.rollNumber,
    required this.isGraduated,
  });
}

/// 🧠 THE INTELLIGENCE ENGINE
class CITParser {
  
  // 📖 1. KNOWLEDGE BASE: Department Codes
  static const Map<String, String> _branchMap = {
    'cse': 'Computer Science & Engineering',
    'co':  'Computer Science',
    'it':  'Information Technology',
    'ece': 'Electronics & Communication',
    'ie':  'Instrumentation Engineering',
    'fet': 'Food Engineering & Technology',
    'ce':  'Civil Engineering',
    'ct':  'Construction Technology',
    'mcd': 'Multimedia Communication',
    'amt': 'Animation & Multimedia',
    'bdes': 'Design',
    'me':  'Mechanical Engineering',
    'ee':  'Electrical Engineering',
  };

  // 🚀 2. MAIN PARSER FUNCTION
  static CITParsedData parseEmail(String email) {
    try {
      // A. SECURITY CHECK: Is it a college email?
      if (!email.endsWith('@cit.ac.in') && !email.endsWith('@citk.ac.in')) {
        return _guestUser(); // It's an Aspirant/Guest
      }

      final localPart = email.split('@')[0].toLowerCase();

      // B. FACULTY CHECK: No numbers in email? (e.g., 'p.ray@cit...')
      if (!RegExp(r'\d').hasMatch(localPart)) {
        return _facultyUser(localPart);
      }

      // C. STUDENT PARSING (The Heavy Logic)
      // Regex Breakdown:
      // ^        : Start
      // ([a-z]+) : Prefix (d=diploma, u=btech, m=mtech) -> Group 1
      // (\d{2})  : Batch (25 = 2025) -> Group 2
      // ([a-z]+) : Branch (cse) -> Group 3
      // (\d+)    : Roll ID (001) -> Group 4
      final match = RegExp(r'^([a-z]+)(\d{2})([a-z]+)(\d+)$').firstMatch(localPart);

      if (match == null) {
        // Has numbers but doesn't look like a student ID -> Staff/Admin
        return _facultyUser(localPart);
      }

      // Extract Raw Data
      final prefix = match.group(1)!;
      final batchCode = match.group(2)!;
      final branchCode = match.group(3)!;
      final idCode = match.group(4)!;

      // Process Data
      final int batchYear = int.parse("20$batchCode"); // 25 -> 2025
      final String branchName = _branchMap[branchCode] ?? branchCode.toUpperCase();
      
      // Determine Degree
      String degree = "B.Tech";
      int maxSemesters = 8;
      
      if (prefix.startsWith('d')) { degree = "Diploma"; maxSemesters = 6; }
      else if (prefix.startsWith('m')) { degree = "M.Tech"; maxSemesters = 4; }
      else if (prefix.startsWith('p')) { degree = "PhD"; maxSemesters = 10; }

      // ⏳ TIME TRAVEL LOGIC: Calculate Semester
      final semData = _calculateAutonomousSemester(batchYear, maxSemesters);

      return CITParsedData(
        role: semData['isGraduated'] ? 'alumni' : 'student',
        degree: degree,
        branch: branchName,
        department: branchCode.toUpperCase(),
        batch: batchYear,
        semester: semData['semString'],
        rollNumber: "CIT/$batchCode/${branchCode.toUpperCase()}/$idCode",
        isGraduated: semData['isGraduated'],
      );

    } catch (e) {
      // Failsafe: If anything explodes, return a Guest user instead of crashing
      if (kDebugMode) print("Parser Error: $e");
      return _guestUser();
    }
  }

  // ⏳ 3. THE TIME MACHINE (Calculates Semester based on Today)
  static Map<String, dynamic> _calculateAutonomousSemester(int joinYear, int maxSemesters) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month; // 1=Jan, 12=Dec

    // Logic: 
    // Academic year starts in July (Month 7).
    // If we are in Jan-June (Months 1-6), we are in the EVEN semester of previous year.
    // If we are in July-Dec (Months 7-12), we are in the ODD semester of current year.

    int yearsElapsed = currentYear - joinYear;
    int currentSem;

    if (currentMonth >= 7) {
      // July-Dec: Odd Sem (1, 3, 5...)
      // Year 0 -> Sem 1
      // Year 1 -> Sem 3
      currentSem = (yearsElapsed * 2) + 1;
    } else {
      // Jan-June: Even Sem (2, 4, 6...)
      // But acts as part of previous academic year
      // Year 1 -> Sem 2
      // Year 2 -> Sem 4
      currentSem = (yearsElapsed * 2);
    }

    // Edge Case: Pre-session (Just joined but session hasn't started)
    if (currentSem < 1) currentSem = 1;

    // Check Graduation
    if (currentSem > maxSemesters) {
      return {
        'semString': 'Graduated',
        'isGraduated': true,
      };
    }

    return {
      'semString': '${_ordinal(currentSem)} Semester',
      'isGraduated': false,
    };
  }

  // Helper: Guest User Template
  static CITParsedData _guestUser() {
    return CITParsedData(
      role: 'aspirant',
      degree: 'N/A',
      branch: 'N/A',
      department: 'N/A',
      batch: 0,
      semester: 'N/A',
      rollNumber: 'N/A',
      isGraduated: false,
    );
  }

  // Helper: Faculty Template
  static CITParsedData _facultyUser(String emailPart) {
    return CITParsedData(
      role: 'faculty',
      degree: 'PhD', // Assumed default
      branch: 'Faculty Member',
      department: 'General',
      batch: 0,
      semester: 'N/A',
      rollNumber: emailPart.toUpperCase(),
      isGraduated: false,
    );
  }

  // Helper: "1st", "2nd", "3rd"
  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return "${n}th";
    switch (n % 10) {
      case 1: return "${n}st";
      case 2: return "${n}nd";
      case 3: return "${n}rd";
      default: return "${n}th";
    }
  }
}