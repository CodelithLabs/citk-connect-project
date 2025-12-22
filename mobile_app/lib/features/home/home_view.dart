import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/chatbot/chatbot_view.dart';
import 'package:mobile_app/features/map/map_view.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> pages = [
      const CampusNavigator(),
      const TheBrain(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("CITK Student Connect"),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Campus Navigator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'The Brain',
          ),
        ],
      ),
    );
  }
}

class CampusNavigator extends StatelessWidget {
  const CampusNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapView();
  }
}

class TheBrain extends ConsumerWidget {
  const TheBrain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ChatbotView();
  }
}
