import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:citk_connect/home/models/weather_model.dart';

class WeatherService {
  // 🔑 SECURITY: Fetch from build args (flutter run --dart-define=WEATHER_API_KEY=xyz)
  static const String apiKey = String.fromEnvironment('WEATHER_API_KEY');
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getWeather(String city) async {
    if (apiKey.isEmpty) {
      throw Exception(
          'Weather API Key missing! Add --dart-define=WEATHER_API_KEY=... to run config.');
    }

    final response = await http
        .get(Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
