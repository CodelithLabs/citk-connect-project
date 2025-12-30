import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5, // Monday - Friday
      child: Scaffold(
        appBar: AppBar(
          title: Text("Class Routine", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Mon"),
              Tab(text: "Tue"),
              Tab(text: "Wed"),
              Tab(text: "Thu"),
              Tab(text: "Fri"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDayRoutine("Monday"),
            _buildDayRoutine("Tuesday"),
            _buildDayRoutine("Wednesday"),
            _buildDayRoutine("Thursday"),
            _buildDayRoutine("Friday"),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRoutine(String day) {
    // Mock Data - In a real app, this would come from your JSON or Firestore
    final List<Map<String, String>> classes = [
      {
        "time": "09:30 AM",
        "subject": "Data Structures",
        "room": "Room 204",
        "teacher": "Dr. Barman"
      },
      {
        "time": "11:00 AM",
        "subject": "Digital Logic",
        "room": "Room 101",
        "teacher": "Prof. Das"
      },
      {
        "time": "01:30 PM",
        "subject": "Mathematics III",
        "room": "Hall B",
        "teacher": "Dr. Singh"
      },
      {
        "time": "03:30 PM",
        "subject": "Python Lab",
        "room": "Comp Lab 2",
        "teacher": "Ms. Roy"
      },
    ];

    if (day == "Saturday" || day == "Sunday") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.weekend, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No Classes Today!", style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        // Highlight the first class as "Next/Active" for demo
        final isActive = index == 0; 

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4285F4).withValues(alpha: 0.2) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF4285F4) : Colors.white.withValues(alpha: 0.05),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Time Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls['time']!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cls['room']!,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 20),
              // Vertical Divider
              Container(height: 50, width: 2, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(width: 20),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls['subject']!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          cls['teacher']!,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: index * 100));
      },
    );
  }
}