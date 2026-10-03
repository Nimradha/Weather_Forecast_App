import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../utils/weather_theme.dart';

class DailyForecastCard extends StatelessWidget {
  final List<DailyForecastSummary> dailyList;
  final bool isCelsius;

  const DailyForecastCard({
    super.key,
    required this.dailyList,
    required this.isCelsius,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyList.isEmpty) return const SizedBox.shrink();

    // Find global min and max across all days for normalized progress bars
    double globalMin = dailyList.map((e) => e.minTemp).reduce((a, b) => a < b ? a : b);
    double globalMax = dailyList.map((e) => e.maxTemp).reduce((a, b) => a > b ? a : b);
    if (globalMax == globalMin) globalMax += 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '7-DAY FORECAST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              ...dailyList.map((day) {
                final isToday = DateFormat('yyyy-MM-dd').format(day.date) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                final dayName = isToday ? 'Today' : DateFormat('EEE').format(day.date);

                final minStr = isCelsius
                    ? '${day.minTemp.round()}°'
                    : '${((day.minTemp * 9 / 5) + 32).round()}°';
                final maxStr = isCelsius
                    ? '${day.maxTemp.round()}°'
                    : '${((day.maxTemp * 9 / 5) + 32).round()}°';

                final leftFraction = ((day.minTemp - globalMin) / (globalMax - globalMin)).clamp(0.0, 1.0);
                final rightFraction = ((day.maxTemp - globalMin) / (globalMax - globalMin)).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          dayName,
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.white70,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        WeatherTheme.getWeatherIcon(day.condition),
                        color: WeatherTheme.getWeatherAccentColor(day.condition),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      if (day.maxPop > 15)
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${day.maxPop}%',
                            style: const TextStyle(
                              color: Color(0xFF64D2FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 38),
                      Text(
                        minStr,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalWidth = constraints.maxWidth;
                              final start = totalWidth * leftFraction;
                              final end = totalWidth * rightFraction;
                              final width = (end - start).clamp(10.0, totalWidth);

                              return Stack(
                                children: [
                                  Positioned(
                                    left: start.clamp(0.0, totalWidth - width),
                                    width: width,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF48CAE4),
                                            Color(0xFFFFD166),
                                            Color(0xFFFF6B6B),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        maxStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
