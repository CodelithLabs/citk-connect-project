import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:citk_connect/home/models/weather_model.dart';

class WeatherService {
  final String apiKey = 'YOUR_API_KEY';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getWeather(String city) async {
    final response = await http.get(Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
