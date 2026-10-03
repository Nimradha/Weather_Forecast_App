import 'package:flutter/material.dart';

class WeatherTheme {
  static LinearGradient getGradientForCondition(String condition, {bool isNight = false}) {
    if (isNight) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ],
      );
    }

    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2980B9),
            Color(0xFF6DD5FA),
            Color(0xFFFFFFFF),
          ],
        );
      case 'rain':
      case 'drizzle':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF373B44),
            Color(0xFF4286F4),
          ],
        );
      case 'thunderstorm':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF141E30),
            Color(0xFF243B55),
          ],
        );
      case 'snow':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF83A4D4),
            Color(0xFFB6FBFF),
          ],
        );
      case 'clouds':
      case 'fog':
      case 'mist':
      case 'atmosphere':
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A6073),
            Color(0xFF3A7BD5),
          ],
        );
    }
  }

  static IconData getWeatherIcon(String condition, {bool isNight = false}) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'fog':
      case 'mist':
      case 'atmosphere':
        return Icons.blur_on_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  static Color getWeatherAccentColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return const Color(0xFFFFD166);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF4CC9F0);
      case 'thunderstorm':
        return const Color(0xFFF72585);
      case 'snow':
        return const Color(0xFFE0FAFF);
      default:
        return const Color(0xFF48CAE4);
    }
  }
}
