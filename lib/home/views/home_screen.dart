import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:citk_connect/auth/services/auth_service.dart';
import 'package:citk_connect/home/models/weather_model.dart';
import 'package:citk_connect/home/services/weather_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await _authService.signOut();
              context.go('/auth');
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () {},
            icon: CircleAvatar(
              backgroundImage: NetworkImage(_user?.photoURL ?? ''),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(_user?.displayName ?? ''),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text(
                  'Hello ${_user?.displayName ?? 'User'} 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ).animate().fadeIn(duration: 600.ms).slideX(),
                const SizedBox(height: 20),
                const WeatherCard().animate().fadeIn(delay: 300.ms, duration: 600.ms).slideX(),
                const SizedBox(height: 20),
                const GrayBox().animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(),
                const SizedBox(height: 20),
                const GrayBox().animate().fadeIn(delay: 900.ms, duration: 600.ms).slideX(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.location_on)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.explore)),
            const SizedBox(width: 40), // The notch
            IconButton(onPressed: () {}, icon: const Icon(Icons.people)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService();
  late Future<Weather> _weather;

  @override
  void initState() {
    super.initState();
    _weather = _weatherService.getWeather('London');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Weather>(
      future: _weather,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final weather = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weather.cityName, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text('${weather.temperature.round()}°C', style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(weather.weatherDescription.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        Image.network(
                          'https://openweathermap.org/img/w/${weather.icon}.png',
                          width: 50,
                          height: 50,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Humidity: ${weather.humidity}%', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        Text('Wind: ${weather.windSpeed} km/h', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const CircularProgressIndicator();
      },
    );
  }
}

class GrayBox extends StatelessWidget {
  const GrayBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15.0),
      ),
    ).animate().shimmer(duration: 1200.ms);
  }
}

