import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showServerDialog(context),
            tooltip: 'Add Server',
          ),
        ],
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final servers = settings.settings.servers;
          if (servers.isEmpty) {
            return const Center(
              child: Text('No servers configured'),
            );
          }

          return ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              final isActive = server.name == settings.settings.activeServerId;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.dns,
                    color: isActive ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(server.name),
                  subtitle: Text(server.url),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            settings.setActiveServer(server.name);
                            Navigator.pop(context);
                          },
                          tooltip: 'Set Active',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showServerDialog(
                          context,
                          existingServer: server,
                        ),
                        tooltip: 'Edit Server',
                      ),
                      if (!isActive || servers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(context, server),
                          tooltip: 'Delete Server',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showServerDialog(
    BuildContext context, {
    CaddyServer? existingServer,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingServer?.name);
    final urlController = TextEditingController(text: existingServer?.url);
    final timeoutController = TextEditingController(
      text: existingServer?.timeout.inSeconds.toString() ?? '10',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingServer == null ? 'Add Server' : 'Edit Server'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  hintText: 'e.g., Production Server',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a server name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'e.g., http://localhost:2019',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a server URL';
                  }
                  try {
                    final uri = Uri.parse(value);
                    if (!uri.hasScheme || !uri.hasAuthority) {
                      return 'Please enter a valid URL';
                    }
                  } catch (_) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: timeoutController,
                decoration: const InputDecoration(
                  labelText: 'Timeout (seconds)',
                  hintText: 'e.g., 10',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a timeout';
                  }
                  final timeout = int.tryParse(value);
                  if (timeout == null || timeout < 1) {
                    return 'Please enter a valid timeout';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!context.mounted) return;

      final settings = context.read<SettingsService>();
      final newServer = CaddyServer(
        name: nameController.text,
        url: urlController.text,
        timeout: Duration(seconds: int.parse(timeoutController.text)),
      );

      try {
        if (existingServer != null) {
          await settings.updateServer(existingServer.name, newServer);
        } else {
          await settings.addServer(newServer);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, CaddyServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${server.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      try {
        await context.read<SettingsService>().removeServer(server.name);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
