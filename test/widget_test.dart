import 'package:flutter_test/flutter_test.dart';
import 'package:weather_forecast/main.dart';

void main() {
  testWidgets('Weather app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WeatherApp());

    // Verify that WeatherCast header is present
    expect(find.text('WeatherCast'), findsOneWidget);
  });
}
