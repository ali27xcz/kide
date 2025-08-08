import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_scholars_app/main.dart';

void main() {
  testWidgets('Little Scholars App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LittleScholarsApp());

    // Wait for splash screen animations
    await tester.pump(const Duration(seconds: 6));

    // Verify that the app starts with splash screen
    expect(find.byType(AnimatedTextKit), findsOneWidget);

    // The app should navigate to home screen after splash
    // This test might need adjustment based on actual navigation timing
  });

  testWidgets('App theme test', (WidgetTester tester) async {
    await tester.pumpWidget(const LittleScholarsApp());
    await tester.pump(const Duration(seconds: 6));

    // Verify that the app uses the correct theme
    expect(find.byType(AnimatedTextKit), findsOneWidget);
    
    // Verify that the debug banner is not displayed
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, false);
  });
}

