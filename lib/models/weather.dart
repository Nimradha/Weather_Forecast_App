class Weather {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final String mainCondition;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int windDegree;
  final int pressure;
  final int visibility;
  final int cloudiness;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime lastUpdated;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.mainCondition,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.windDegree,
    required this.pressure,
    required this.visibility,
    required this.cloudiness,
    required this.sunrise,
    required this.sunset,
    required this.lastUpdated,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weatherList = (json['weather'] as List?) ?? [];
    final weatherFirst = weatherList.isNotEmpty ? weatherList[0] : {};
    final wind = json['wind'] ?? {};
    final sys = json['sys'] ?? {};
    final clouds = json['clouds'] ?? {};

    return Weather(
      cityName: json['name'] ?? 'Unknown Location',
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0.0,
      mainCondition: weatherFirst['main'] ?? 'Clear',
      description: weatherFirst['description'] ?? 'Clear sky',
      icon: weatherFirst['icon'] ?? '01d',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      windDegree: (wind['deg'] as num?)?.toInt() ?? 0,
      pressure: (main['pressure'] as num?)?.toInt() ?? 1013,
      visibility: (json['visibility'] as num?)?.toInt() ?? 10000,
      cloudiness: (clouds['all'] as num?)?.toInt() ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        ((sys['sunrise'] as num?)?.toInt() ?? 0) * 1000,
        isUtc: true,
      ).toLocal(),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        ((sys['sunset'] as num?)?.toInt() ?? 0) * 1000,
        isUtc: true,
      ).toLocal(),
      lastUpdated: DateTime.now(),
    );
  }
}

class ForecastPoint {
  final DateTime dateTime;
  final double temperature;
  final double feelsLike;
  final String mainCondition;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pop; // Probability of precipitation (0-100%)

  ForecastPoint({
    required this.dateTime,
    required this.temperature,
    required this.feelsLike,
    required this.mainCondition,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pop,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weatherList = (json['weather'] as List?) ?? [];
    final weatherFirst = weatherList.isNotEmpty ? weatherList[0] : {};
    final wind = json['wind'] ?? {};

    return ForecastPoint(
      dateTime: DateTime.tryParse(json['dt_txt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            ((json['dt'] as num?)?.toInt() ?? 0) * 1000,
          ),
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      mainCondition: weatherFirst['main'] ?? 'Clear',
      description: weatherFirst['description'] ?? 'Clear',
      icon: weatherFirst['icon'] ?? '01d',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      pop: (((json['pop'] as num?)?.toDouble() ?? 0.0) * 100).round(),
    );
  }
}

class DailyForecastSummary {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String condition;
  final String icon;
  final int maxPop;

  DailyForecastSummary({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.icon,
    required this.maxPop,
  });
}
