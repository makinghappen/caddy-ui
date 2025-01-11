import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddyui/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that the app shows the Caddy Manager title
    expect(find.text('Caddy Manager'), findsOneWidget);
  });
}
