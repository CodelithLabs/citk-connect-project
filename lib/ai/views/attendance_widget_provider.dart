import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

final attendanceWidgetProvider = Provider((ref) => AttendanceWidgetProvider());

class AttendanceWidgetProvider {
  static const String _androidWidgetName = 'AttendanceWidget';
  static const String _iOSWidgetName = 'AttendanceWidget';

  Future<void> updateWidgetData({
    required double overallPercentage,
    required String status,
  }) async {
    // Save data to shared storage
    await HomeWidget.saveWidgetData<double>(
        'overall_percentage', overallPercentage);
    await HomeWidget.saveWidgetData<String>('status', status);

    // Trigger widget update
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }
}
