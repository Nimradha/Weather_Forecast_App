import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../utils/weather_theme.dart';

class HourlyForecastCard extends StatelessWidget {
  final ForecastPoint forecast;
  final bool isCelsius;

  const HourlyForecastCard({
    super.key,
    required this.forecast,
    required this.isCelsius,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h a').format(forecast.dateTime);
    final temp = isCelsius
        ? '${forecast.temperature.round()}°'
        : '${((forecast.temperature * 9 / 5) + 32).round()}°';

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  WeatherTheme.getWeatherIcon(
                    forecast.mainCondition,
                    isNight: forecast.dateTime.hour < 6 || forecast.dateTime.hour >= 18,
                  ),
                  color: WeatherTheme.getWeatherAccentColor(forecast.mainCondition),
                  size: 26,
                ),
                Text(
                  temp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (forecast.pop > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop, size: 10, color: Color(0xFF64D2FF)),
                      Text(
                        '${forecast.pop}%',
                        style: const TextStyle(
                          color: Color(0xFF64D2FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
