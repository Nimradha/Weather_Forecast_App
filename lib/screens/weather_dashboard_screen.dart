import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../utils/weather_theme.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/weather_detail_card.dart';

class WeatherDashboardScreen extends StatefulWidget {
  final String initialCity;
  final bool isCelsius;
  final ValueChanged<bool>? onUnitChanged;
  final VoidCallback? onNavigateToSaved;

  const WeatherDashboardScreen({
    super.key,
    this.initialCity = 'London',
    this.isCelsius = true,
    this.onUnitChanged,
    this.onNavigateToSaved,
  });

  @override
  State<WeatherDashboardScreen> createState() => WeatherDashboardScreenState();
}

class WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _popularCities = [
    'London',
    'Colombo',
    'Tokyo',
    'Paris',
    'New York',
    'Sydney',
    'Dubai',
    'Singapore',
  ];

  Weather? _currentWeather;
  List<ForecastPoint> _hourlyForecast = [];
  List<DailyForecastSummary> _dailyForecast = [];

  bool _isLoading = true;
  String? _errorMessage;
  late bool _isCelsius;
  late String _activeCity;

  @override
  void initState() {
    super.initState();
    _isCelsius = widget.isCelsius;
    _activeCity = widget.initialCity;
    _loadWeatherData(_activeCity);
  }

  @override
  void didUpdateWidget(covariant WeatherDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCelsius != widget.isCelsius) {
      setState(() => _isCelsius = widget.isCelsius);
    }
    if (oldWidget.initialCity != widget.initialCity && widget.initialCity != _activeCity) {
      loadCity(widget.initialCity);
    }
  }

  void loadCity(String city) {
    _searchController.text = city;
    _loadWeatherData(city);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await WeatherService.fetchWeatherData(city);
      if (mounted) {
        setState(() {
          _currentWeather = result['weather'];
          _hourlyForecast = result['hourlyForecast'] ?? [];
          _dailyForecast = result['dailyForecast'] ?? [];
          _activeCity = city;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: WeatherService.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('OpenWeatherMap API Key', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your custom API key below (Optional - the app has an automatic fallback to Open-Meteo if left empty or inactive).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter API Key',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4)),
            onPressed: () {
              WeatherService.apiKey = keyController.text.trim();
              Navigator.pop(ctx);
              _loadWeatherData(_activeCity);
            },
            child: const Text('Save & Reload', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condition = _currentWeather?.mainCondition ?? 'Clear';
    final now = DateTime.now();
    final isNight = _currentWeather != null
        ? (now.isBefore(_currentWeather!.sunrise) || now.isAfter(_currentWeather!.sunset))
        : false;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: WeatherTheme.getGradientForCondition(condition, isNight: isNight),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1E293B),
            onRefresh: () => _loadWeatherData(_activeCity),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // App Header & Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 12),
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCityChips(),
                      ],
                    ),
                  ),
                ),

                // Main Content / Loading / Error
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Fetching live weather data...',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorWidget(),
                  )
                else if (_currentWeather != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroWeatherCard(_currentWeather!, isNight),
                          const SizedBox(height: 20),
                          _buildHourlySection(),
                          const SizedBox(height: 20),
                          DailyForecastCard(
                            dailyList: _dailyForecast,
                            isCelsius: _isCelsius,
                          ),
                          const SizedBox(height: 20),
                          _buildWeatherDetailsGrid(_currentWeather!),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'WeatherCast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Unit Switcher (°C / °F)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _isCelsius = true);
                      widget.onUnitChanged?.call(true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCelsius ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          color: _isCelsius ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isCelsius = false);
                      widget.onUnitChanged?.call(false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_isCelsius ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '°F',
                        style: TextStyle(
                          color: !_isCelsius ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (widget.onNavigateToSaved != null)
              IconButton(
                icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
                tooltip: 'Saved Locations',
                onPressed: widget.onNavigateToSaved,
              ),
            IconButton(
              icon: const Icon(Icons.key_rounded, color: Colors.white),
              tooltip: 'API Settings',
              onPressed: _showApiKeyDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _loadWeatherData(value.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Search city (e.g. Tokyo, Paris)...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                      onPressed: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          _loadWeatherData(_searchController.text.trim());
                        }
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildCityChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _popularCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = _popularCities[index];
          final isSelected = city.toLowerCase() == _activeCity.toLowerCase();
          return ActionChip(
            label: Text(city),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black87 : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.12),
            side: BorderSide(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              _searchController.text = city;
              _loadWeatherData(city);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroWeatherCard(Weather weather, bool isNight) {
    final temp = _isCelsius
        ? '${weather.temperature.round()}°'
        : '${((weather.temperature * 9 / 5) + 32).round()}°';
    final feels = _isCelsius
        ? '${weather.feelsLike.round()}°'
        : '${((weather.feelsLike * 9 / 5) + 32).round()}°';
    final min = _isCelsius
        ? '${weather.tempMin.round()}°'
        : '${((weather.tempMin * 9 / 5) + 32).round()}°';
    final max = _isCelsius
        ? '${weather.tempMax.round()}°'
        : '${((weather.tempMax * 9 / 5) + 32).round()}°';

    final dateFormatted = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                weather.cityName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatted,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    WeatherTheme.getWeatherIcon(weather.mainCondition, isNight: isNight),
                    color: WeatherTheme.getWeatherAccentColor(weather.mainCondition),
                    size: 56,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                temp,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 78,
                  fontWeight: FontWeight.w200,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                weather.description.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Feels like $feels', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(width: 14),
                  const Text('•', style: TextStyle(color: Colors.white54)),
                  const SizedBox(width: 14),
                  Text('H: $max  L: $min', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlySection() {
    if (_hourlyForecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'HOURLY FORECAST',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _hourlyForecast.length,
            itemBuilder: (context, index) {
              return HourlyForecastCard(
                forecast: _hourlyForecast[index],
                isCelsius: _isCelsius,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailsGrid(Weather weather) {
    final sunriseStr = DateFormat('h:mm a').format(weather.sunrise);
    final sunsetStr = DateFormat('h:mm a').format(weather.sunset);
    final feels = _isCelsius
        ? '${weather.feelsLike.round()}°C'
        : '${((weather.feelsLike * 9 / 5) + 32).round()}°F';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'WEATHER CONDITIONS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            WeatherDetailCard(
              icon: Icons.water_drop_outlined,
              title: 'HUMIDITY',
              value: '${weather.humidity}%',
              subtitle: weather.humidity > 65 ? 'High Humidity' : 'Comfortable',
            ),
            WeatherDetailCard(
              icon: Icons.air_rounded,
              title: 'WIND SPEED',
              value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
              subtitle: 'Direction: ${weather.windDegree}°',
            ),
            WeatherDetailCard(
              icon: Icons.thermostat_rounded,
              title: 'FEELS LIKE',
              value: feels,
              subtitle: 'Humidity effect included',
            ),
            WeatherDetailCard(
              icon: Icons.speed_rounded,
              title: 'PRESSURE',
              value: '${weather.pressure} hPa',
              subtitle: 'Atmospheric pressure',
            ),
            WeatherDetailCard(
              icon: Icons.wb_sunny_outlined,
              title: 'SUNRISE & SUNSET',
              value: sunriseStr,
              subtitle: 'Sunset at $sunsetStr',
            ),
            WeatherDetailCard(
              icon: Icons.cloud_queue_rounded,
              title: 'CLOUD COVER',
              value: '${weather.cloudiness}%',
              subtitle: 'Visibility: ${(weather.visibility / 1000).toStringAsFixed(1)} km',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 54),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Load Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'An unexpected error occurred.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _loadWeatherData(_activeCity),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
