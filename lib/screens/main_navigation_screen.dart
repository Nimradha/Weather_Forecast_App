import 'dart:ui';
import 'package:flutter/material.dart';
import 'weather_dashboard_screen.dart';
import 'saved_cities_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _activeCity = 'London';
  bool _isCelsius = true;

  final List<String> _savedCities = [
    'London',
    'Colombo',
    'Tokyo',
    'New York',
    'Paris',
    'Sydney',
  ];

  final GlobalKey<WeatherDashboardScreenState> _dashboardKey = GlobalKey<WeatherDashboardScreenState>();

  void _onCitySelected(String city) {
    setState(() {
      _activeCity = city;
      _currentIndex = 0; // Switch to dashboard tab
    });
    _dashboardKey.currentState?.loadCity(city);
  }

  void _onCityAdded(String city) {
    setState(() {
      if (!_savedCities.any((c) => c.toLowerCase() == city.toLowerCase())) {
        _savedCities.insert(0, city);
      }
    });
  }

  void _onCityRemoved(String city) {
    setState(() {
      _savedCities.removeWhere((c) => c.toLowerCase() == city.toLowerCase());
    });
  }

  void _toggleUnits(bool isCelsius) {
    setState(() {
      _isCelsius = isCelsius;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WeatherDashboardScreen(
        key: _dashboardKey,
        initialCity: _activeCity,
        isCelsius: _isCelsius,
        onUnitChanged: _toggleUnits,
        onNavigateToSaved: () => setState(() => _currentIndex = 1),
      ),
      SavedCitiesScreen(
        savedCities: _savedCities,
        activeCity: _activeCity,
        isCelsius: _isCelsius,
        onCitySelected: _onCitySelected,
        onCityAdded: _onCityAdded,
        onCityRemoved: _onCityRemoved,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.85),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
              ),
            ),
            child: NavigationBar(
              height: 65,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedIndex: _currentIndex,
              indicatorColor: const Color(0xFF48CAE4).withOpacity(0.25),
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.cloud_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.cloud_rounded, color: Color(0xFF48CAE4)),
                  label: 'Weather',
                ),
                NavigationDestination(
                  icon: Icon(Icons.format_list_bulleted_rounded, color: Colors.white70),
                  selectedIcon: Icon(Icons.location_on_rounded, color: Color(0xFF48CAE4)),
                  label: 'Locations',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
