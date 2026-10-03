import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../utils/weather_theme.dart';

class SavedCitiesScreen extends StatefulWidget {
  final List<String> savedCities;
  final String activeCity;
  final bool isCelsius;
  final Function(String city) onCitySelected;
  final Function(String city) onCityAdded;
  final Function(String city) onCityRemoved;

  const SavedCitiesScreen({
    super.key,
    required this.savedCities,
    required this.activeCity,
    required this.isCelsius,
    required this.onCitySelected,
    required this.onCityAdded,
    required this.onCityRemoved,
  });

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  final Map<String, Weather?> _cityWeatherData = {};
  final Map<String, bool> _cityLoading = {};
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllCityWeather();
  }

  @override
  void didUpdateWidget(covariant SavedCitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savedCities.length != widget.savedCities.length) {
      _loadAllCityWeather();
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCityWeather() async {
    for (final city in widget.savedCities) {
      if (!_cityWeatherData.containsKey(city)) {
        _fetchCityWeather(city);
      }
    }
  }

  Future<void> _fetchCityWeather(String city) async {
    setState(() {
      _cityLoading[city] = true;
    });

    try {
      final res = await WeatherService.fetchWeatherData(city);
      if (mounted) {
        setState(() {
          _cityWeatherData[city] = res['weather'];
          _cityLoading[city] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cityLoading[city] = false;
        });
      }
    }
  }

  void _showAddCityDialog() {
    _addController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the name of a city, region, or country to add to your list.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.done,
                onSubmitted: (val) => _handleAddSubmitted(val, ctx),
                decoration: InputDecoration(
                  hintText: 'e.g. Melbourne, Toronto, Kandy...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF48CAE4), size: 28),
                    onPressed: () => _handleAddSubmitted(_addController.text, ctx),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Singapore', 'Dubai', 'Rome', 'Seoul', 'Auckland', 'Madrid']
                    .map(
                      (suggested) => ActionChip(
                        label: Text(suggested),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          _addController.text = suggested;
                          _handleAddSubmitted(suggested, ctx);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAddSubmitted(String city, BuildContext dialogContext) {
    final clean = city.trim();
    if (clean.isNotEmpty) {
      if (!widget.savedCities.any((c) => c.toLowerCase() == clean.toLowerCase())) {
        widget.onCityAdded(clean);
        _fetchCityWeather(clean);
      }
      Navigator.pop(dialogContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saved Locations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF48CAE4), size: 28),
            tooltip: 'Add City',
            onPressed: _showAddCityDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.savedCities.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.savedCities.length,
              itemBuilder: (context, index) {
                final city = widget.savedCities[index];
                final weather = _cityWeatherData[city];
                final isLoading = _cityLoading[city] ?? false;
                final isActive = city.toLowerCase() == widget.activeCity.toLowerCase();

                return Dismissible(
                  key: ValueKey(city),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    widget.onCityRemoved(city);
                    setState(() {
                      _cityWeatherData.remove(city);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$city removed from saved locations'),
                        backgroundColor: const Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: _buildCityCard(city, weather, isLoading, isActive),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF48CAE4),
        foregroundColor: Colors.black87,
        elevation: 6,
        onPressed: _showAddCityDialog,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 70, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No Saved Locations',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your favorite cities.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48CAE4),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _showAddCityDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add City', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(String city, Weather? weather, bool isLoading, bool isActive) {
    final condition = weather?.mainCondition ?? 'Clear';
    final now = DateTime.now();
    final isNight = weather != null
        ? (now.isBefore(weather.sunrise) || now.isAfter(weather.sunset))
        : false;

    final temp = weather != null
        ? (widget.isCelsius
            ? '${weather.temperature.round()}°'
            : '${((weather.temperature * 9 / 5) + 32).round()}°')
        : '--°';

    final min = weather != null
        ? (widget.isCelsius
            ? '${weather.tempMin.round()}°'
            : '${((weather.tempMin * 9 / 5) + 32).round()}°')
        : '--°';

    final max = weather != null
        ? (widget.isCelsius
            ? '${weather.tempMax.round()}°'
            : '${((weather.tempMax * 9 / 5) + 32).round()}°')
        : '--°';

    final timeStr = DateFormat('h:mm a').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => widget.onCitySelected(city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: WeatherTheme.getGradientForCondition(condition, isNight: isNight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
                  width: isActive ? 2.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                weather?.cityName ?? city,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weather?.description.toUpperCase() ?? (isLoading ? 'UPDATING...' : 'LIVE FORECAST'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      else ...[
                        Icon(
                          WeatherTheme.getWeatherIcon(condition, isNight: isNight),
                          color: WeatherTheme.getWeatherAccentColor(condition),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          temp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          'H: $max  L: $min',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
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
