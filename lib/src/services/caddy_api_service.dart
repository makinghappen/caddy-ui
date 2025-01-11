import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/caddy_config.dart';

import '../models/settings.dart';

class CaddyApiService {
  final CaddyServer server;

  CaddyApiService(this.server);

  void _logRequest(String method, String url,
      {Map<String, String>? headers, String? body}) {
    print('🌐 REQUEST: $method $url');
    if (headers != null) print('Headers: $headers');
    if (body != null) print('Body: $body');
  }

  void _logResponse(http.Response response) {
    print('📥 RESPONSE: ${response.statusCode}');
    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(response.body);
        print('Body: ${const JsonEncoder.withIndent('  ').convert(json)}');
      } catch (_) {
        print('Body: ${response.body}');
      }
    }
  }

  void _logError(String message, {Object? error, StackTrace? stackTrace}) {
    print('❌ ERROR: $message');
    if (error != null) print('Error details: $error');
    if (stackTrace != null) print('Stack trace:\n$stackTrace');
  }

  Future<T> _handleResponse<T>(
    Future<http.Response> request,
    T Function(dynamic) parser, {
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) async {
    try {
      _logRequest(method, url, headers: headers, body: body);
      final response = await request.timeout(server.timeout);
      _logResponse(response);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // For 204 responses or empty bodies, return null for methods that expect it
        if (response.statusCode == 204 || response.body.isEmpty) {
          return parser({});
        }
        final decoded = json.decode(response.body);
        return parser(decoded);
      }

      throw CaddyApiException(
        'Request failed',
        statusCode: response.statusCode,
        details: response.body,
      );
    } on http.ClientException catch (e) {
      _logError('Connection error', error: e);
      throw CaddyApiException('Connection error: ${e.message}');
    } on TimeoutException catch (e, stack) {
      _logError('Request timed out', error: e, stackTrace: stack);
      throw CaddyApiException('Request timed out');
    } on FormatException catch (e, stack) {
      _logError('Invalid response format', error: e, stackTrace: stack);
      throw CaddyApiException('Invalid response format: ${e.message}');
    }
  }

  Future<CaddyConfig> getConfig([String? path]) async {
    final url = '${server.url}/config/${path ?? ""}';
    final request = http.get(Uri.parse(url));
    return _handleResponse(
      request,
      (json) => CaddyConfig.fromJson(json),
      method: 'GET',
      url: url,
    );
  }

  Future<void> setConfig(CaddyConfig config, [String? path]) async {
    final url = Uri.parse('${server.url}/config/${path ?? ""}');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(config.toJson());
    final request = http.post(
      url,
      headers: headers,
      body: body,
    );
    await _handleResponse(
      request,
      (_) => null,
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );
  }

  Future<void> putConfig(CaddyConfig config, [String? path]) async {
    final url = Uri.parse('${server.url}/config/${path ?? ""}');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(config.toJson());
    final request = http.put(
      url,
      headers: headers,
      body: body,
    );
    await _handleResponse(
      request,
      (_) => null,
      method: 'PUT',
      url: url.toString(),
      headers: headers,
      body: body,
    );
  }

  Future<void> patchConfig(Map<String, dynamic> updates, [String? path]) async {
    final url = Uri.parse('${server.url}/config/${path ?? ""}');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(updates);
    final request = http.patch(
      url,
      headers: headers,
      body: body,
    );
    await _handleResponse(
      request,
      (_) => null,
      method: 'PATCH',
      url: url.toString(),
      headers: headers,
      body: body,
    );
  }

  Future<void> deleteConfig([String? path]) async {
    final url = Uri.parse('${server.url}/config/${path ?? ""}');
    final request = http.delete(url);
    await _handleResponse(
      request,
      (_) => null,
      method: 'DELETE',
      url: url.toString(),
    );
  }

  Future<void> reloadConfig() async {
    final url = '${server.url}/load/';
    final request = http.post(Uri.parse(url));
    await _handleResponse(
      request,
      (_) => null,
      method: 'POST',
      url: url,
    );
  }

  Future<void> stopServer() async {
    final url = '${server.url}/stop/';
    final request = http.post(Uri.parse(url));
    await _handleResponse(
      request,
      (_) => null,
      method: 'POST',
      url: url,
    );
  }

  Future<CaddyConfig> adaptConfig(String config) async {
    final url = '${server.url}/adapt';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(config);
    final request = http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    return _handleResponse(
      request,
      (json) => CaddyConfig.fromJson(json),
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
    );
  }

  Future<Map<String, dynamic>> getPkiCaInfo(String id) async {
    final url = '${server.url}/pki/ca/$id';
    final request = http.get(Uri.parse(url));
    return _handleResponse(
      request,
      (json) => json,
      method: 'GET',
      url: url,
    );
  }

  Future<Map<String, dynamic>> getPkiCaCertificates(String id) async {
    final url = '${server.url}/pki/ca/$id/certificates';
    final request = http.get(Uri.parse(url));
    return _handleResponse(
      request,
      (json) => json,
      method: 'GET',
      url: url,
    );
  }

  Future<Map<String, dynamic>> getReverseProxyUpstreams() async {
    final url = '${server.url}/reverse_proxy/upstreams';
    final request = http.get(Uri.parse(url));
    return _handleResponse(
      request,
      (json) => json,
      method: 'GET',
      url: url,
    );
  }

  Future<CaddyConfig> getConfigById(String id) async {
    final url = '${server.url}/config/@id/$id';
    final request = http.get(Uri.parse(url));
    return _handleResponse(
      request,
      (json) => CaddyConfig.fromJson(json),
      method: 'GET',
      url: url,
    );
  }

  Future<void> updateConfigPath(String path, dynamic value) async {
    // Convert dot notation to URL path, properly handling array indices
    final parts = path.split('.');
    final urlParts = <String>[];

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];

      // If this is 'handle', we need to handle it specially
      if (part == 'handle') {
        // If next part is a number, it's an array index for handle
        if (i + 1 < parts.length && int.tryParse(parts[i + 1]) != null) {
          urlParts.add('routes');
          urlParts.add('0');
          urlParts.add('handle');
          urlParts.add(parts[i + 1]);
          i++; // Skip the next part since we've used it
          continue;
        }
      }

      // For other numeric indices, append to previous part
      if (int.tryParse(part) != null && i > 0) {
        final lastPart = urlParts.removeLast();
        urlParts.add('$lastPart/$part');
      } else {
        urlParts.add(part);
      }
    }

    final urlPath = '/config/${urlParts.join('/')}';
    final url = Uri.parse('${server.url}$urlPath');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(value);

    print('🔧 Updating config');
    print('🔧 URL: $url');
    print('🔧 New value: $body');

    // Use PATCH for all operations
    print('🔧 Using PATCH for config update');
    final patchRequest = http.patch(
      url,
      headers: headers,
      body: body,
    );

    await _handleResponse(
      patchRequest,
      (_) => null,
      method: 'PATCH',
      url: url.toString(),
      headers: headers,
      body: body,
    );
  }

  Future<ServerStatus> getStatus() async {
    final url = '${server.url}/';
    try {
      print('🔍 Fetching server status from: $url');
      final response = await http.get(Uri.parse(url)).timeout(server.timeout);
      print('🔍 Status response code: ${response.statusCode}');
      print('🔍 Status response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('🔍 Empty response body but status 200 - server is running');
          return ServerStatus(
            isRunning: true,
            version: 'unknown',
            raw: {},
          );
        }
        final json = jsonDecode(response.body);
        return ServerStatus.fromJson(json);
      }

      print('🔍 Non-200 status code: ${response.statusCode}');
      return ServerStatus(
        isRunning: false,
        version: 'unknown',
        raw: {},
      );
    } catch (e) {
      print('🔍 Error getting status: $e');
      return ServerStatus(
        isRunning: false,
        version: 'unknown',
        raw: {},
      );
    }
  }
}
