import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingServiceProvider =
    StateNotifierProvider<OnboardingService, bool>((ref) {
  return OnboardingService();
});

class OnboardingService extends StateNotifier<bool> {
  OnboardingService() : super(false);

  static const _key = 'seenOnboarding';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }
}
