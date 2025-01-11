import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caddyui/main.dart';
import 'package:caddyui/src/services/settings_service.dart';
import 'package:caddyui/src/models/settings.dart';

class MockSettingsService extends ChangeNotifier implements SettingsService {
  final Settings _settings = Settings(
    servers: [CaddyServer(name: 'Test Server', url: 'http://localhost:2019')],
    activeServerId: 'Test Server',
  );

  @override
  Settings get settings => _settings;

  @override
  CaddyServer? get activeServer => _settings.activeServer;

  @override
  Future<void> addServer(CaddyServer server) async {}

  @override
  Future<void> updateServer(String oldName, CaddyServer updatedServer) async {}

  @override
  Future<void> removeServer(String name) async {}

  @override
  Future<void> setActiveServer(String name) async {}
}

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    final mockSettings = MockSettingsService();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsService>.value(
        value: mockSettings,
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Caddy Manager'), findsOneWidget);
  });
}
