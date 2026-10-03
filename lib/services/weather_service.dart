import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // OpenWeatherMap API key
  static String apiKey = '564000612cf3c52670ddf888f465a231';
  static const String _owmBaseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetches current weather and forecast for a given city
  static Future<Map<String, dynamic>> fetchWeatherData(String cityName) async {
    final cleanCity = cityName.trim();
    if (cleanCity.isEmpty) {
      throw Exception('Please enter a city name.');
    }

    try {
      // 1. Try OpenWeatherMap API
      final owmResult = await _fetchFromOpenWeatherMap(cleanCity);
      if (owmResult != null) {
        return owmResult;
      }
    } catch (e) {
      // If OWM fails (e.g. invalid key 401 or network), fallback to Open-Meteo
    }

    // 2. Reliable Fallback using Open-Meteo (No API Key Required)
    return await _fetchFromOpenMeteo(cleanCity);
  }

  static Future<Map<String, dynamic>?> _fetchFromOpenWeatherMap(String city) async {
    final weatherUri = Uri.parse(
      '$_owmBaseUrl/weather?q=${Uri.encodeComponent(city)}&units=metric&appid=$apiKey',
    );
    final forecastUri = Uri.parse(
      '$_owmBaseUrl/forecast?q=${Uri.encodeComponent(city)}&units=metric&appid=$apiKey',
    );

    final weatherRes = await http.get(weatherUri).timeout(const Duration(seconds: 8));

    if (weatherRes.statusCode == 200) {
      final weatherJson = jsonDecode(weatherRes.body);
      final weather = Weather.fromJson(weatherJson);

      List<ForecastPoint> forecastPoints = [];
      final forecastRes = await http.get(forecastUri).timeout(const Duration(seconds: 8));
      if (forecastRes.statusCode == 200) {
        final forecastJson = jsonDecode(forecastRes.body);
        final List list = forecastJson['list'] ?? [];
        forecastPoints = list.map((item) => ForecastPoint.fromJson(item)).toList();
      }

      return {
        'weather': weather,
        'hourlyForecast': forecastPoints,
        'dailyForecast': _groupDailyForecast(forecastPoints),
      };
    } else if (weatherRes.statusCode == 404) {
      throw Exception('City "$city" not found. Please check spelling.');
    } else if (weatherRes.statusCode == 401) {
      // Invalid or unactivated API key - trigger fallback
      return null;
    }
    return null;
  }

  /// Open-Meteo Geocoding + Weather API (Works globally without requiring an API key)
  static Future<Map<String, dynamic>> _fetchFromOpenMeteo(String city) async {
    // Normalize query string (e.g., "srilanka" -> "sri lanka")
    String query = city.trim();
    if (query.toLowerCase() == 'srilanka') {
      query = 'Sri Lanka';
    }

    // Geocode city/location name to lat & lon (fetch top 10 to rank by population/relevance)
    final geoUri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=en&format=json',
    );
    final geoRes = await http.get(geoUri).timeout(const Duration(seconds: 8));

    if (geoRes.statusCode != 200) {
      throw Exception('Network error while searching location.');
    }

    final geoData = jsonDecode(geoRes.body);
    final results = geoData['results'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('Location "$city" not found. Please check spelling.');
    }

    // Sort to prioritize highest population or exact country/capital match
    results.sort((a, b) {
      final popA = (a['population'] as num?)?.toInt() ?? 0;
      final popB = (b['population'] as num?)?.toInt() ?? 0;
      return popB.compareTo(popA);
    });

    final location = results[0];
    final double lat = (location['latitude'] as num).toDouble();
    final double lon = (location['longitude'] as num).toDouble();
    final String resolvedCity = location['name'] ?? query;
    final String country = location['country'] ?? '';
    final String displayName = (country.isNotEmpty && country.toLowerCase() != resolvedCity.toLowerCase())
        ? '$resolvedCity, $country'
        : resolvedCity;

    // Fetch live weather + hourly & daily forecasts
    final weatherUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,cloud_cover'
      '&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max'
      '&timezone=auto',
    );

    final weatherRes = await http.get(weatherUri).timeout(const Duration(seconds: 8));
    if (weatherRes.statusCode != 200) {
      throw Exception('Failed to fetch weather data for $resolvedCity.');
    }

    final data = jsonDecode(weatherRes.body);
    final current = data['current'] ?? {};
    final daily = data['daily'] ?? {};
    final hourly = data['hourly'] ?? {};

    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (current['is_day'] as num?)?.toInt() == 1;
    final conditionData = _mapWeatherCode(weatherCode, isDay);

    DateTime sunrise = DateTime.now();
    DateTime sunset = DateTime.now();
    if (daily['sunrise'] != null && (daily['sunrise'] as List).isNotEmpty) {
      sunrise = DateTime.tryParse(daily['sunrise'][0]) ?? DateTime.now();
    }
    if (daily['sunset'] != null && (daily['sunset'] as List).isNotEmpty) {
      sunset = DateTime.tryParse(daily['sunset'][0]) ?? DateTime.now();
    }

    final weather = Weather(
      cityName: displayName,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      tempMin: (daily['temperature_2m_min'] != null && (daily['temperature_2m_min'] as List).isNotEmpty)
          ? (daily['temperature_2m_min'][0] as num).toDouble()
          : 0.0,
      tempMax: (daily['temperature_2m_max'] != null && (daily['temperature_2m_max'] as List).isNotEmpty)
          ? (daily['temperature_2m_max'][0] as num).toDouble()
          : 0.0,
      mainCondition: conditionData['main']!,
      description: conditionData['description']!,
      icon: conditionData['icon']!,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      windDegree: (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
      pressure: (current['surface_pressure'] as num?)?.toInt() ?? 1013,
      visibility: 10000,
      cloudiness: (current['cloud_cover'] as num?)?.toInt() ?? 0,
      sunrise: sunrise,
      sunset: sunset,
      lastUpdated: DateTime.now(),
    );

    // Parse Hourly (next 24 hours)
    List<ForecastPoint> hourlyForecast = [];
    final hourlyTimes = (hourly['time'] as List?) ?? [];
    final hourlyTemps = (hourly['temperature_2m'] as List?) ?? [];
    final hourlyFeels = (hourly['apparent_temperature'] as List?) ?? [];
    final hourlyCodes = (hourly['weather_code'] as List?) ?? [];
    final hourlyPops = (hourly['precipitation_probability'] as List?) ?? [];
    final hourlyHumids = (hourly['relative_humidity_2m'] as List?) ?? [];
    final hourlyWinds = (hourly['wind_speed_10m'] as List?) ?? [];

    final now = DateTime.now();
    for (int i = 0; i < hourlyTimes.length && hourlyForecast.length < 24; i++) {
      final dt = DateTime.tryParse(hourlyTimes[i]) ?? DateTime.now();
      if (dt.isAfter(now.subtract(const Duration(hours: 1)))) {
        final code = (hourlyCodes[i] as num).toInt();
        final cond = _mapWeatherCode(code, dt.hour >= 6 && dt.hour < 18);
        hourlyForecast.add(ForecastPoint(
          dateTime: dt,
          temperature: (hourlyTemps[i] as num).toDouble(),
          feelsLike: (hourlyFeels[i] as num).toDouble(),
          mainCondition: cond['main']!,
          description: cond['description']!,
          icon: cond['icon']!,
          humidity: (hourlyHumids[i] as num).toInt(),
          windSpeed: (hourlyWinds[i] as num).toDouble(),
          pop: (hourlyPops[i] as num).toInt(),
        ));
      }
    }

    // Parse Daily (7-day forecast)
    List<DailyForecastSummary> dailyForecast = [];
    final dailyTimes = (daily['time'] as List?) ?? [];
    final dailyCodes = (daily['weather_code'] as List?) ?? [];
    final dailyMaxs = (daily['temperature_2m_max'] as List?) ?? [];
    final dailyMins = (daily['temperature_2m_min'] as List?) ?? [];
    final dailyPops = (daily['precipitation_probability_max'] as List?) ?? [];

    for (int i = 0; i < dailyTimes.length; i++) {
      final dt = DateTime.tryParse(dailyTimes[i]) ?? DateTime.now();
      final code = (dailyCodes[i] as num).toInt();
      final cond = _mapWeatherCode(code, true);

      dailyForecast.add(DailyForecastSummary(
        date: dt,
        minTemp: (dailyMins[i] as num).toDouble(),
        maxTemp: (dailyMaxs[i] as num).toDouble(),
        condition: cond['main']!,
        icon: cond['icon']!,
        maxPop: (dailyPops[i] as num).toInt(),
      ));
    }

    return {
      'weather': weather,
      'hourlyForecast': hourlyForecast,
      'dailyForecast': dailyForecast,
    };
  }

  static List<DailyForecastSummary> _groupDailyForecast(List<ForecastPoint> points) {
    final Map<String, List<ForecastPoint>> grouped = {};
    for (var p in points) {
      final key = '${p.dateTime.year}-${p.dateTime.month.toString().padLeft(2, '0')}-${p.dateTime.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    List<DailyForecastSummary> summaries = [];
    grouped.forEach((dateStr, items) {
      double min = items.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
      double max = items.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
      int maxPop = items.map((e) => e.pop).reduce((a, b) => a > b ? a : b);
      final midItem = items[items.length ~/ 2];

      summaries.add(DailyForecastSummary(
        date: DateTime.parse(dateStr),
        minTemp: min,
        maxTemp: max,
        condition: midItem.mainCondition,
        icon: midItem.icon,
        maxPop: maxPop,
      ));
    });

    return summaries;
  }

  static Map<String, String> _mapWeatherCode(int code, bool isDay) {
    if (code == 0) {
      return {
        'main': 'Clear',
        'description': isDay ? 'Sunny' : 'Clear Sky',
        'icon': isDay ? '01d' : '01n',
      };
    } else if (code == 1 || code == 2) {
      return {
        'main': 'Clouds',
        'description': 'Partly Cloudy',
        'icon': isDay ? '02d' : '02n',
      };
    } else if (code == 3) {
      return {
        'main': 'Clouds',
        'description': 'Overcast',
        'icon': '04d',
      };
    } else if (code >= 45 && code <= 48) {
      return {
        'main': 'Atmosphere',
        'description': 'Foggy',
        'icon': '50d',
      };
    } else if (code >= 51 && code <= 67) {
      return {
        'main': 'Rain',
        'description': 'Drizzle / Light Rain',
        'icon': '10d',
      };
    } else if (code >= 71 && code <= 77) {
      return {
        'main': 'Snow',
        'description': 'Snowfall',
        'icon': '13d',
      };
    } else if (code >= 80 && code <= 82) {
      return {
        'main': 'Rain',
        'description': 'Heavy Showers',
        'icon': '09d',
      };
    } else if (code >= 95 && code <= 99) {
      return {
        'main': 'Thunderstorm',
        'description': 'Thunderstorm',
        'icon': '11d',
      };
    } else {
      return {
        'main': 'Clouds',
        'description': 'Cloudy',
        'icon': '03d',
      };
    }
  }
}
