import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SmartAttendanceCard extends StatefulWidget {
  const SmartAttendanceCard({super.key});

  @override
  State<SmartAttendanceCard> createState() => _SmartAttendanceCardState();
}

class _SmartAttendanceCardState extends State<SmartAttendanceCard> {
  bool _isLoading = false;
  double _attendancePercentage = 0.75;

  // CIT Kokrajhar Coordinates (Approximate)
  final double _targetLat = 26.47;
  final double _targetLong = 90.26;
  final double _radiusInMeters = 100;

  Future<void> _markAttendance() async {
    setState(() => _isLoading = true);

    try {
      // 1. Check Service Status
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showDialog("Location Disabled", "Please enable location services.",
            isError: true);
        return;
      }

      // 2. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showDialog("Permission Denied", "Location permission is required.",
              isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showDialog(
            "Permission Denied", "Location permissions are permanently denied.",
            isError: true);
        return;
      }

      // 3. Get Position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 4. Calculate Distance
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _targetLat,
        _targetLong,
      );

      // 5. Verify Range
      if (distanceInMeters <= _radiusInMeters) {
        // Simulate Backend API Call
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _attendancePercentage =
                (_attendancePercentage + 0.01).clamp(0.0, 1.0);
          });
          final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
          _showDialog("Success! 🎉", "Attendance Marked for $dateStr");
        }
      } else {
        _showDialog("Out of Range",
            "You are ${distanceInMeters.toStringAsFixed(1)}m away. Move closer to campus.",
            isError: true);
      }
    } catch (e) {
      _showDialog("Error", e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isError ? Colors.redAccent : Colors.green,
            )),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1F3A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _attendancePercentage,
                      strokeWidth: 8,
                      backgroundColor:
                          isDark ? Colors.white10 : Colors.grey.shade200,
                      color: const Color(0xFF4CAF50),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "${(_attendancePercentage * 100).toInt()}%",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Info & Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Attendance",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mark your presence now",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _markAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Mark Attendance",
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
