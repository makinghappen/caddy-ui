import 'dart:convert';

class CaddyConfig {
  final Map<String, dynamic> raw;

  CaddyConfig(this.raw);

  factory CaddyConfig.fromJson(Map<String, dynamic> json) {
    return CaddyConfig(json);
  }

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(raw);
  }

  // Helper methods to access common config properties
  dynamic getPath(String path) {
    List<String> parts = path.split('.');
    dynamic current = raw;
    for (String part in parts) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  CaddyConfig copyWith({Map<String, dynamic>? updates}) {
    if (updates == null) return this;

    final newConfig = Map<String, dynamic>.from(raw);
    updates.forEach((key, value) {
      if (value == null) {
        newConfig.remove(key);
      } else {
        newConfig[key] = value;
      }
    });

    return CaddyConfig(newConfig);
  }
}

class ServerStatus {
  final bool isRunning;
  final String version;
  final Map<String, dynamic> raw;

  ServerStatus({
    required this.isRunning,
    required this.version,
    required this.raw,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    print(
        '🔍 ServerStatus JSON: ${const JsonEncoder.withIndent('  ').convert(json)}');

    // If we can get any data from the server, it must be running
    final isRunning = json.isNotEmpty;

    print('🔍 Server running: $isRunning (based on response data presence)');
    print('🔍 Available fields: ${json.keys.join(', ')}');

    return ServerStatus(
      isRunning: isRunning,
      version: json['version'] ?? 'unknown',
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

class CaddyApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  CaddyApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    final parts = [message];
    if (statusCode != null) parts.add('(Status: $statusCode)');
    if (details != null) parts.add('\nDetails: $details');
    return parts.join(' ');
  }
}
