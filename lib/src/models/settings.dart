class CaddyServer {
  final String name;
  final String url;
  final Duration timeout;

  CaddyServer({
    required this.name,
    required this.url,
    this.timeout = const Duration(seconds: 10),
  });

  factory CaddyServer.fromJson(Map<String, dynamic> json) {
    return CaddyServer(
      name: json['name'] as String,
      url: json['url'] as String,
      timeout: Duration(seconds: json['timeout'] as int? ?? 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'timeout': timeout.inSeconds,
    };
  }

  CaddyServer copyWith({
    String? name,
    String? url,
    Duration? timeout,
  }) {
    return CaddyServer(
      name: name ?? this.name,
      url: url ?? this.url,
      timeout: timeout ?? this.timeout,
    );
  }
}

class Settings {
  final List<CaddyServer> servers;
  final String? activeServerId;

  Settings({
    required this.servers,
    this.activeServerId,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      servers: (json['servers'] as List<dynamic>)
          .map((e) => CaddyServer.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeServerId: json['activeServerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servers': servers.map((e) => e.toJson()).toList(),
      'activeServerId': activeServerId,
    };
  }

  Settings copyWith({
    List<CaddyServer>? servers,
    String? activeServerId,
  }) {
    return Settings(
      servers: servers ?? this.servers,
      activeServerId: activeServerId ?? this.activeServerId,
    );
  }

  CaddyServer? get activeServer {
    if (activeServerId == null || servers.isEmpty) return null;
    try {
      return servers.firstWhere((s) => s.name == activeServerId);
    } catch (_) {
      return null;
    }
  }
}
