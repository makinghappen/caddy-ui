import 'package:flutter/material.dart';
import '../services/caddy_api_service.dart';
import '../models/caddy_config.dart';
import '../models/config_node.dart';
import '../models/settings.dart';
import '../ui/settings_page.dart';
import 'config_editor/config_editor_page.dart';

class CaddyManagerPage extends StatefulWidget {
  final CaddyServer server;

  const CaddyManagerPage({
    super.key,
    required this.server,
  });

  @override
  State<CaddyManagerPage> createState() => _CaddyManagerPageState();
}

class _CaddyManagerPageState extends State<CaddyManagerPage> {
  late final CaddyApiService _apiService;
  CaddyConfig? _config;
  ServerStatus? _status;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _apiService = CaddyApiService(widget.server);
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Try to load config first
      final config = await _apiService.getConfig();
      setState(() => _config = config);

      // If we got config, server must be running even if status endpoint returns empty
      final status = await _apiService.getStatus();
      setState(() {
        if (status.isRunning == false && _config != null) {
          // Override status if we have config but status shows stopped
          _status = ServerStatus(
            isRunning: true,
            version: status.version,
            raw: {'config': 'loaded', ...status.raw},
          );
        } else {
          _status = status;
        }
      });
    } on CaddyApiException catch (e) {
      _showError('Failed to load data: ${e.message}');
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadConfig() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.reloadConfig();
      await _loadInitialData();
      _showSuccess('Config reloaded successfully');
    } on CaddyApiException catch (e) {
      _showError('Failed to reload config: ${e.message}');
    } catch (e) {
      _showError('Unexpected error while reloading config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopServer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stop Server'),
        content: const Text('Are you sure you want to stop the Caddy server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop Server'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.stopServer();
      _showSuccess('Server stopped successfully');
    } on CaddyApiException catch (e) {
      _showError('Failed to stop server: ${e.message}');
    } catch (e) {
      _showError('Unexpected error while stopping server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConfigChanged(ConfigNode node, dynamic value) async {
    setState(() => _isLoading = true);
    try {
      // Skip the 'root' prefix
      var path =
          node.path.startsWith('root.') ? node.path.substring(5) : node.path;

      // Split path into parts and handle special cases
      final parts = path.split('.');
      final processedParts = <String>[];
      var lastArrayIndex = -1;
      var lastArrayParent = '';
      var hasId = false;

      // Process each part
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];

        // Handle array indices
        if (int.tryParse(part) != null) {
          lastArrayIndex = int.parse(part);
          lastArrayParent = processedParts.join('/');
          continue;
        }

        // Handle @id special case
        if (part == '@id' && i + 1 < parts.length) {
          hasId = true;
          processedParts.add('@id');
          processedParts.add(parts[++i]);
          continue;
        }

        processedParts.add(part);
      }

      // Construct final path
      if (lastArrayIndex >= 0) {
        // We have a pending array index
        if (hasId) {
          // For @id paths, include array index in the path
          processedParts.add(lastArrayIndex.toString());
          path = processedParts.join('/');
        } else {
          // For regular paths, use parent path
          path = lastArrayParent;

          // Try to get current array to determine if it exists
          try {
            final array = await _apiService.getConfig(path);
            final currentArray = array.raw as List;

            if (lastArrayIndex >= currentArray.length) {
              // For appending, use POST with /...
              path = '$path/...';
              value = [value]; // Wrap in array for POST .../...
            } else {
              // For updating existing element, use PATCH on parent array
              currentArray[lastArrayIndex] = value;
              value = currentArray;
            }
          } catch (e) {
            // If array doesn't exist or error occurs
            if (lastArrayIndex == 0) {
              // Create new array with single element
              value = [value];
            } else {
              // Create new array with null padding
              value = List.filled(lastArrayIndex + 1, null)
                ..[lastArrayIndex] = value;
            }
          }
        }
      } else {
        path = processedParts.join('/');
      }

      await _apiService.updateConfigPath(path, value);
      await _loadInitialData();
      _showSuccess('Configuration updated successfully');
    } on CaddyApiException catch (e) {
      _showError('Failed to update config: ${e.message}');
    } catch (e) {
      _showError('Unexpected error while updating config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caddy Manager - ${widget.server.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Status section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _status?.isRunning == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: _status?.isRunning == true
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _status?.isRunning == true
                                  ? 'Server Running'
                                  : 'Server Stopped',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Version: ${_status?.version ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Action buttons
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _reloadConfig,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Reload'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _stopServer,
                      icon: const Icon(Icons.stop, size: 20),
                      label: const Text('Stop'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_config == null)
            const Expanded(
              child: Center(child: Text('No configuration loaded')),
            )
          else
            Expanded(
              child: ConfigEditorPage(
                config: _config!,
                onConfigChanged: (node, value) =>
                    _handleConfigChanged(node, value),
              ),
            ),
        ],
      ),
    );
  }
}
