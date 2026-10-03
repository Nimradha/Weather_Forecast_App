# 🌦️ WeatherCast - Flutter Weather Forecast App

A cross-platform Flutter application that displays real-time weather information and multi-day forecasts using REST APIs.

---

## 🌟 Key Features

- **Live Weather Dashboard**: Real-time temperature, condition description, feels-like temperature, and high/low ranges.
- **Dynamic Weather Theming**: Animated background gradients that change according to current conditions (Sunny, Rain, Thunderstorm, Snow, Cloudy, Fog, Night).
- **24-Hour Hourly Forecast**: Interactive horizontal timeline displaying hourly temperature trends and precipitation probability.
- **7-Day Weather Forecast**: Weekly overview with visual min/max temperature range indicators.
- **Comprehensive Weather Metrics**: 6 condition detail cards (Humidity, Wind Speed & Direction, Atmospheric Pressure, Sunrise & Sunset, Cloud Cover & Visibility).
- **Saved Locations / Favorites**: Multi-city management with real-time temperature cards, swipe-to-delete, and instant dashboard switching.
- **Global Search**: Search any city worldwide with query normalization and relevance ranking.
- **Unit Toggle**: Instant conversion between Celsius (°C) and Fahrenheit (°F).
- **Error & Loading States**: Smooth loading feedback and error handling with a retry mechanism.

---

## 🛠️ Tech Stack & Skills

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3.5+)
- **Networking & REST APIs**: [`http`](https://pub.dev/packages/http)
- **Data Parsing**: Strongly-typed JSON deserialization (`factory .fromJson`)
- **Typography & Styling**: [`google_fonts`](https://pub.dev/packages/google_fonts) (Inter font family), Material 3 Glassmorphism
- **Date/Time Formatting**: [`intl`](https://pub.dev/packages/intl)
- **Supported Platforms**: Android, iOS, Web, Windows Desktop

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Android Studio / VS Code / Xcode (for iOS)

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/weather_forecast.git
   cd weather_forecast
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   # Run on Android / Emulator
   flutter run

   # Or run on Chrome Web
   flutter run -d chrome

   # Or run on Windows Desktop
   flutter run -d windows
   ```

---

## 🔑 API Configuration

This app supports **OpenWeatherMap API** with an automatic zero-configuration fallback:
- To use your own OpenWeatherMap key, set it in `lib/services/weather_service.dart` or tap the **🔑 Key Icon** inside the app.

---

## 📂 Project Structure

```
lib/
├── models/
│   └── weather.dart                # Weather & Forecast Data Models
├── services/
│   └── weather_service.dart        # REST API & Geocoding Service
├── utils/
│   └── weather_theme.dart          # Dynamic Gradients, Colors & Weather Icons
├── widgets/
│   ├── weather_detail_card.dart    # 2x2 Metric Detail Cards
│   ├── hourly_forecast_card.dart   # Horizontal Hourly Forecast Item
│   └── daily_forecast_card.dart    # 7-Day Forecast Row with Range Indicator
├── screens/
│   ├── main_navigation_screen.dart   # Navigation Shell & Glassmorphic Tab Bar
│   ├── weather_dashboard_screen.dart # Live Dashboard & Forecast Screen
│   └── saved_cities_screen.dart      # Multi-City Saved Favorites Screen
└── main.dart                       # App Entry Point & Theme Setup
```
