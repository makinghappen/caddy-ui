import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService extends ChangeNotifier {
  static const _settingsKey = 'caddy_settings';
  final SharedPreferences _prefs;
  Settings _settings;

  SettingsService._(this._prefs, this._settings);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    Settings settings;
    if (settingsJson != null) {
      try {
        settings = Settings.fromJson(json.decode(settingsJson));
      } catch (e) {
        // If settings are corrupted, start fresh
        settings = Settings(servers: []);
      }
    } else {
      // Default settings with localhost server
      settings = Settings(
        servers: [
          CaddyServer(
            name: 'Local Server',
            url: 'http://localhost:2019',
          ),
        ],
        activeServerId: 'Local Server',
      );
    }

    return SettingsService._(prefs, settings);
  }

  Settings get settings => _settings;
  CaddyServer? get activeServer => _settings.activeServer;

  Future<void> addServer(CaddyServer server) async {
    final servers = List<CaddyServer>.from(_settings.servers);

    // Check for duplicate names
    if (servers.any((s) => s.name == server.name)) {
      throw Exception('A server with this name already exists');
    }

    servers.add(server);
    await _updateSettings(_settings.copyWith(servers: servers));
  }

  Future<void> updateServer(String oldName, CaddyServer updatedServer) async {
    final servers = List<CaddyServer>.from(_settings.servers);
    final index = servers.indexWhere((s) => s.name == oldName);

    if (index == -1) {
      throw Exception('Server not found');
    }

    // Check for duplicate names if name is being changed
    if (oldName != updatedServer.name &&
        servers.any((s) => s.name == updatedServer.name)) {
      throw Exception('A server with this name already exists');
    }

    servers[index] = updatedServer;

    // Update active server ID if needed
    String? activeServerId = _settings.activeServerId;
    if (activeServerId == oldName) {
      activeServerId = updatedServer.name;
    }

    await _updateSettings(_settings.copyWith(
      servers: servers,
      activeServerId: activeServerId,
    ));
  }

  Future<void> removeServer(String name) async {
    final servers = List<CaddyServer>.from(_settings.servers)
      ..removeWhere((s) => s.name == name);

    // Clear active server if it was removed
    String? activeServerId = _settings.activeServerId;
    if (activeServerId == name) {
      activeServerId = servers.isNotEmpty ? servers.first.name : null;
    }

    await _updateSettings(_settings.copyWith(
      servers: servers,
      activeServerId: activeServerId,
    ));
  }

  Future<void> setActiveServer(String name) async {
    if (!_settings.servers.any((s) => s.name == name)) {
      throw Exception('Server not found');
    }
    await _updateSettings(_settings.copyWith(activeServerId: name));
  }

  Future<void> _updateSettings(Settings newSettings) async {
    _settings = newSettings;
    await _prefs.setString(_settingsKey, json.encode(newSettings.toJson()));
    notifyListeners();
  }
}
