import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../ai/views/attendance_widget_provider.dart';
import '../../../../ai/views/attendance_repo_impl.dart';
import '../../../../domain/entities/attendance_entry.dart';
import '../../../../domain/entities/routine_entry.dart';
import '../../../../ai/providers/context_provider.dart';

class AttendanceDashboard extends ConsumerStatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  ConsumerState<AttendanceDashboard> createState() =>
      _AttendanceDashboardState();
}

class _AttendanceDashboardState extends ConsumerState<AttendanceDashboard> {
  bool _isLoading = false;
  String? _selectedSubject;
  AttendanceStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to view attendance"));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Attendance',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTodayTab(user.uid),
            _buildHistoryTab(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(String userId) {
    return FutureBuilder<List<RoutineEntry>>(
      future: ref.read(routineProvider).getTodayRoutine(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading routine: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final routines = snapshot.data ?? [];
        if (routines.isEmpty) {
          return Center(
            child: Text(
              'No classes scheduled for today',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            return _buildClassCard(routine, userId);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(String userId) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now;

    return FutureBuilder<List<AttendanceEntry>>(
      future: ref.read(attendanceRepositoryProvider).getAttendance(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'No attendance records found',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          );
        }

        // Filter Logic
        final subjects = entries.map((e) => e.subjectId).toSet().toList();
        subjects.sort();

        var filteredEntries = entries.where((e) {
          if (_selectedSubject != null && e.subjectId != _selectedSubject) {
            return false;
          }
          if (_selectedStatus != null && e.status != _selectedStatus) {
            return false;
          }
          return true;
        }).toList();

        filteredEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final percentage = _calculatePercentage(filteredEntries);

        return Column(
          children: [
            _buildTrendChart(entries),
            _buildFilters(subjects),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredEntries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child:
                          _buildSummaryCard(percentage, filteredEntries.length),
                    );
                  }
                  final entry = filteredEntries[index - 1];
                  return _buildHistoryCard(entry);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(List<String> subjects) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Subject Filter
          PopupMenuButton<String?>(
            initialValue: _selectedSubject,
            onSelected: (String? value) {
              setState(() {
                _selectedSubject = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('All Subjects'),
                ),
                ...subjects.map((String subject) {
                  return PopupMenuItem<String?>(
                    value: subject,
                    child: Text(subject),
                  );
                }),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedSubject != null
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedSubject != null
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 16,
                    color: _selectedSubject != null
                        ? const Color(0xFF6C63FF)
                        : Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSubject ?? 'Subject',
                    style: GoogleFonts.inter(
                      color: _selectedSubject != null
                          ? const Color(0xFF6C63FF)
                          : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _selectedSubject != null
                        ? const Color(0xFF6C63FF)
                        : Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status Filters
          Wrap(
            spacing: 8,
            children: AttendanceStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              return FilterChip(
                label: Text(status.name.toUpperCase()),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF6C63FF),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<AttendanceEntry> entries) {
    // Calculate last 7 days stats
    final now = DateTime.now();
    final days = List.generate(7, (index) {
      final d = now.subtract(Duration(days: 6 - index));
      return DateTime(d.year, d.month, d.day);
    });

    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days Trend',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final dayEntries =
                    entries.where((e) => e.isForDate(day)).toList();
                final total = dayEntries.length;
                final present = dayEntries
                    .where((e) => e.status == AttendanceStatus.present)
                    .length;

                double percentage = total == 0 ? 0 : present / total;

                // Visual height factor (min height for empty days to show placeholder)
                double heightFactor = total == 0 ? 0.05 : percentage;
                if (heightFactor == 0 && total > 0)
                  heightFactor = 0.05; // Show small red bar for 0%

                Color barColor;
                if (total == 0) {
                  barColor = Colors.white.withValues(alpha: 0.05);
                } else if (percentage >= 0.75) {
                  barColor = const Color(0xFF6C63FF);
                } else if (percentage >= 0.5) {
                  barColor = Colors.orangeAccent;
                } else {
                  barColor = Colors.redAccent;
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              width: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('E').format(day)[0], // M, T, W...
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePercentage(List<AttendanceEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final presentCount =
        entries.where((e) => e.status == AttendanceStatus.present).length;
    return (presentCount / entries.length) * 100;
  }

  Widget _buildSummaryCard(double percentage, int totalClasses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Attendance',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalClasses Classes',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(RoutineEntry routine, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.subjectName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${routine.startTime} - ${routine.endTime} • ${routine.room ?? "N/A"}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _markPresent(routine, userId),
            icon: const Icon(Icons.check_circle_outline,
                color: Color(0xFF6C63FF), size: 32),
            tooltip: 'Mark Present',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(AttendanceEntry entry) {
    final dateStr = DateFormat('MMM d, yyyy').format(entry.timestamp);
    final timeStr = DateFormat('h:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: entry.status == AttendanceStatus.present
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.status == AttendanceStatus.present
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: entry.status == AttendanceStatus.present
                  ? const Color(0xFF6C63FF)
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectId,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $timeStr',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.status.name.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markPresent(RoutineEntry routine, String userId) async {
    setState(() => _isLoading = true);
    try {
      final entry = AttendanceEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subjectId: routine.subjectCode,
        timestamp: DateTime.now(),
        status: AttendanceStatus.present,
        type: ClassType.lecture,
        semesterId: 'current', // Ideally fetched from profile
        createdAt: DateTime.now(),
      );

      // 1. Mark in Repository (Local + Sync Queue)
      await ref.read(attendanceRepositoryProvider).markAttendance(entry);

      // 2. Update Home Screen Widget via Provider
      await ref.read(attendanceWidgetProvider).updateWidgetData(
            overallPercentage: 85.0, // Placeholder: Calculate actual % here
            status: 'Present: ${routine.subjectName}',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${routine.subjectName} as Present'),
            backgroundColor: const Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
