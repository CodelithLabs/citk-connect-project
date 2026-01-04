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
    required this.role, required this.degree, required this.branch,
    required this.batch, required this.semester, required this.rollNumber,
    required this.department, required this.isGraduated,
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

  static CITParsedData parseEmail(String email) {
    final localPart = email.split('@')[0].toLowerCase();
    
    // 1. 🕵️‍♂️ Faculty Check (No numbers = Faculty)
    if (!RegExp(r'\d').hasMatch(localPart)) {
      // Try to find dept in name (e.g. 'hod_cse'), else 'General'
      String dept = 'General';
      for (var key in branchMap.keys) {
        if (localPart.contains(key)) {
          dept = branchMap[key]!;
          break;
        }
      }
      return CITParsedData(
        role: 'faculty', degree: 'N/A', branch: 'N/A', batch: 0,
        semester: 'N/A', rollNumber: 'FAC-${localPart.toUpperCase()}',
        department: dept, isGraduated: false,
      );
    }

    // 2. 🎓 Student Parsing
    try {
      // Regex: Prefix(d/u) + Year(2 digits) + Branch(letters) + ID(digits)
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

      // ⏳ Time Machine Logic
      final now = DateTime.now();
      int sem = (now.year - batchYear) * 2;
      if (now.month >= 7) sem += 1; // July+ is Odd Sem
      if (sem < 1) sem = 1;

      // Graduation Check
      bool isGraduated = false;
      String semStr = "$sem${_getOrdinal(sem)} Sem";
      String role = 'student';
      
      if (sem > maxSem) {
        role = 'alumni';
        isGraduated = true;
        semStr = "Graduated";
      }

      return CITParsedData(
        role: role, degree: degree, branch: branch, batch: batchYear,
        semester: semStr, 
        rollNumber: "CIT/$batchStr/${branchCode.toUpperCase()}/$idNo",
        department: branch, isGraduated: isGraduated,
      );
    } catch (e) {
      // Fallback for irregular emails
      return CITParsedData(
        role: 'student', degree: 'Unknown', branch: 'Unknown', batch: 0,
        semester: '1st Sem', rollNumber: localPart.toUpperCase(),
        department: 'Unknown', isGraduated: false,
      );
    }
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return "th";
    switch (n % 10) { case 1: return "st"; case 2: return "nd"; case 3: return "rd"; default: return "th"; }
  }
}