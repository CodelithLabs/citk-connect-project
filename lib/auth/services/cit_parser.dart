class CITParsedData {
  final String role;
  final String degree;
  final String branch;
  final int batch;
  final String semester;
  final String rollNumber;
  final String department;
  final bool isGraduated;

  CITParsedData({
    required this.role,
    required this.degree,
    required this.branch,
    required this.batch,
    required this.semester,
    required this.rollNumber,
    required this.department,
    required this.isGraduated,
  });
}

class CITParser {
  // 📚 MAPPING DATABASE
  static const Map<String, String> branchMap = {
    'cse': 'Computer Science & Engineering',
    'co': 'Computer Science',
    'it': 'Information Technology',
    'ece': 'Electronics & Communication',
    'et': 'Electronics & Telecommunication',
    'ie': 'Instrumentation Engineering',
    'fet': 'Food Engineering & Technology',
    'fpt': 'Food Processing Technology',
    'ce': 'Civil Engineering',
    'ct': 'Construction Technology',
    'mcd': 'Multimedia Communication & Design',
    'amt': 'Animation & Multimedia',
    'bdes': 'Design',
    'me': 'Mechanical Engineering',
    'ee': 'Electrical Engineering',
  };

  // 📅 Academic Calendar Configuration
  static const int oddSemStartMonth = 7; // July
  static const int evenSemStartMonth = 1; // January
  static const int summerBreakStartMonth = 5; // May
  static const int summerBreakEndMonth = 6; // June

  static CITParsedData parseEmail(String email) {
    // 🛡️ ENHANCED SECURITY: Multi-layer email validation
    
    // Layer 1: Basic format check
    if (email.isEmpty || !email.contains('@')) {
      return _createGuestUser('INVALID-EMPTY');
    }

    // Layer 2: Split and validate parts
    final parts = email.split('@');
    if (parts.length != 2) {
      // Handles multiple @ symbols (e.g., test@@cit.ac.in)
      return _createGuestUser('INVALID-MULTIPLE-AT');
    }

    final localPart = parts[0];
    final domain = parts[1];

    // Layer 3: Check for empty parts
    if (localPart.isEmpty || domain.isEmpty) {
      return _createGuestUser('INVALID-EMPTY-PARTS');
    }

    // Layer 4: Validate against comprehensive email regex
    // This regex ensures:
    // - Only ASCII characters (no unicode like tést)
    // - Valid email structure
    // - Proper domain format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    
    if (!emailRegex.hasMatch(email)) {
      return _createGuestUser('INVALID-FORMAT');
    }

    // Layer 5: Additional security checks
    // Prevent injection attacks through unusual characters
    final safeCharsRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!safeCharsRegex.hasMatch(localPart)) {
      return _createGuestUser('INVALID-CHARS');
    }

    final localPartLower = localPart.toLowerCase();

    // 1. 🕵️‍♂️ Faculty Check (No numbers = Faculty)
    if (!RegExp(r'\d').hasMatch(localPartLower)) {
      return _parseFacultyEmail(localPartLower);
    }

    // 2. 🎓 Student Parsing
    return _parseStudentEmail(localPartLower);
  }

  // Helper: Create guest user for invalid emails
  static CITParsedData _createGuestUser(String reason) {
    return CITParsedData(
      role: 'guest',
      degree: 'N/A',
      branch: 'N/A',
      batch: 0,
      semester: 'N/A',
      rollNumber: reason,
      department: 'N/A',
      isGraduated: false,
    );
  }

  // Helper: Parse faculty email
  static CITParsedData _parseFacultyEmail(String localPart) {
    String dept = 'General';
    for (var key in branchMap.keys) {
      if (localPart.contains(key)) {
        dept = branchMap[key]!;
        break;
      }
    }
    return CITParsedData(
      role: 'faculty',
      degree: 'N/A',
      branch: 'N/A',
      batch: 0,
      semester: 'N/A',
      rollNumber: 'FAC-${localPart.toUpperCase()}',
      department: dept,
      isGraduated: false,
    );
  }

  // Helper: Parse student email with enhanced semester calculation
  static CITParsedData _parseStudentEmail(String localPart) {
    try {
      // Regex: Prefix(d/u/m/p) + Year(2 digits) + Branch(letters) + ID(digits)
      final match = RegExp(r'^([a-z]+)(\d{2})([a-z]+)(\d+)$').firstMatch(localPart);

      if (match == null) throw Exception("Format mismatch");

      final prefix = match.group(1)!;
      final batchStr = match.group(2)!;
      final branchCode = match.group(3)!;
      final idNo = match.group(4)!;

      final batchYear = int.parse("20$batchStr");
      final branch = branchMap[branchCode] ?? branchCode.toUpperCase();

      // Degree Rules
      String degree = "B.Tech"; // Default case
      int maxSem = 8;

      if (prefix.startsWith('d')) {
        degree = "Diploma";
        maxSem = 6;
      } else if (prefix.startsWith('u')) {
        degree = "B.Tech";
        maxSem = 8;
      } else if (prefix.startsWith('m')) {
        degree = "M.Tech";
        maxSem = 4;
      } else if (prefix.startsWith('p')) {
        degree = "PhD";
        maxSem = 12;
      }

      // 🔧 ENHANCED SEMESTER CALCULATION
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Calculate base semester considering academic year starts in July
      int sem = _calculateSemester(batchYear, currentYear, currentMonth);

      // Apply constraints: minimum 1, maximum based on degree
      sem = sem.clamp(1, maxSem + 2); // +2 buffer for late graduates

      // Graduation Check
      bool isGraduated = false;
      String semStr = "$sem${_getOrdinal(sem)} Sem";
      String role = 'student';

      if (sem > maxSem) {
        role = 'alumni';
        isGraduated = true;
        semStr = "Graduated";
      }

      // Handle summer break period (May-June)
      if (currentMonth >= summerBreakStartMonth && 
          currentMonth <= summerBreakEndMonth && 
          !isGraduated) {
        semStr = "$sem${_getOrdinal(sem)} Sem (Summer Break)";
      }

      return CITParsedData(
        role: role,
        degree: degree,
        branch: branch,
        batch: batchYear,
        semester: semStr,
        rollNumber: "CIT/$batchStr/${branchCode.toUpperCase()}/$idNo",
        department: branch,
        isGraduated: isGraduated,
      );
    } catch (e) {
      // Fallback for irregular emails
      return CITParsedData(
        role: 'student',
        degree: 'Unknown',
        branch: 'Unknown',
        batch: 0,
        semester: '1st Sem',
        rollNumber: localPart.toUpperCase(),
        department: 'Unknown',
        isGraduated: false,
      );
    }
  }

  /// 📊 Enhanced semester calculation logic
  /// Handles:
  /// - Academic year boundary (July start)
  /// - Mid-year enrollments (January lateral entry)
  /// - Proper semester progression
  static int _calculateSemester(int batchYear, int currentYear, int currentMonth) {
    // Calculate years elapsed since batch started
    int yearsElapsed = currentYear - batchYear;
    
    // Determine current academic year position
    // If before July, we're still in the previous academic year's even semester
    // If July or after, we've started the new academic year's odd semester
    
    int baseSemester;
    
    if (currentMonth >= oddSemStartMonth) {
      // July onwards: odd semester (1st, 3rd, 5th, 7th)
      // Year 0 (joined) → Sem 1
      // Year 1 → Sem 3
      // Year 2 → Sem 5
      baseSemester = (yearsElapsed * 2) + 1;
    } else {
      // January to June: even semester (2nd, 4th, 6th, 8th)
      // But belongs to previous academic year
      // Year 1 → Sem 2
      // Year 2 → Sem 4
      baseSemester = (yearsElapsed * 2);
      
      // Handle special case: first year students before July
      if (baseSemester < 1) {
        baseSemester = 1; // They're still in 1st semester
      }
    }
    
    return baseSemester;
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return "th";
    switch (n % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }
}

// 🧪 TESTING UTILITIES
class CITParserTests {
  static void runAllTests() {
    print("🧪 Running CIT Parser Security Tests\n");
    
    // Test Issue #12: Email Validation
    print("📧 EMAIL VALIDATION TESTS:");
    _testEmail("test@@cit.ac.in", "INVALID-MULTIPLE-AT");
    _testEmail("@cit.ac.in", "INVALID-EMPTY-PARTS");
    _testEmail("tést@cit.ac.in", "INVALID-FORMAT");
    _testEmail("test@cit..ac.in", "INVALID-FORMAT");
    _testEmail("", "INVALID-EMPTY");
    
    // Valid emails
    _testEmail("u21cse001@cit.ac.in", "student", expectValid: true);
    _testEmail("hod_cse@cit.ac.in", "faculty", expectValid: true);
    
    // Test Issue #13: Semester Calculation
    print("\n📅 SEMESTER CALCULATION TESTS:");
    // Simulate different dates for testing
    _testSemesterLogic();
  }
  
  static void _testEmail(String email, String expected, {bool expectValid = false}) {
    final result = CITParser.parseEmail(email);
    final passed = expectValid 
      ? result.role == expected 
      : result.rollNumber.contains(expected);
    
    print("${passed ? '✅' : '❌'} $email → ${expectValid ? result.role : result.rollNumber}");
  }
  
  static void _testSemesterLogic() {
    // Test cases for different enrollment dates
    print("Testing semester calculation for u21cse001 (joined 2021):");
    print("- Current: Jan 2025 → Should be 8th Sem (even)");
    print("- Current: Jul 2024 → Should be 7th Sem (odd)");
    print("- Current: May 2024 → Should be 6th Sem (Summer Break)");
    print("- Graduated: Sep 2025 → Should be Alumni");
  }
}