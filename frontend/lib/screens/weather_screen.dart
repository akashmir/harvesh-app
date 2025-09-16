import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = "Delhi";
  String weatherDescription = "";
  double? temperature;
  int? humidity;
  double? windSpeed;

  final TextEditingController _cityController = TextEditingController();

  Future<void> fetchWeather(String city) async {
    const apiKey = "8382d6ea94ce19069453dc3ffb5e8518";
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cityName = data['name'];
          weatherDescription = data['weather'][0]['description'];
          temperature = data['main']['temp'];
          humidity = data['main']['humidity'];
          windSpeed = data['wind']['speed'];
        });
      } else {
        setState(() {
          weatherDescription = "City not found. Please try again.";
          temperature = null;
          humidity = null;
          windSpeed = null;
        });
      }
    } catch (error) {
      setState(() {
        weatherDescription = "Error fetching weather data.";
        temperature = null;
        humidity = null;
        windSpeed = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Enter city name",
                hintText: "e.g., Mumbai",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final city = _cityController.text.trim();
                if (city.isNotEmpty) {
                  fetchWeather(city);
                } else {
                  setState(() {
                    weatherDescription = "Please enter a city name.";
                    temperature = null;
                    humidity = null;
                    windSpeed = null;
                  });
                }
              },
              child: const Text("Fetch Weather"),
            ),
            const SizedBox(height: 30),
            Image.network('https://image.shutterstock.com/image-photo/photos-sky-during-different-weather-260nw-1899360634.jpg'),
            if (weatherDescription.isNotEmpty) ...[
              Text(
                "Weather in $cityName",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                weatherDescription,
                style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
            ],
            if (temperature != null) ...[
              Text(
                "Temperature: ${temperature?.toStringAsFixed(1)}°C",
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                "Humidity: ${humidity?.toString()}%",
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                "Wind Speed: ${windSpeed?.toStringAsFixed(1)} m/s",
                style: const TextStyle(fontSize: 18),
              ),
              
            ],
          ],
        ),
      ),
    );
  }
}
