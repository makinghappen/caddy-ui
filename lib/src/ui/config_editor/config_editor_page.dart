import 'package:flutter/material.dart';
import '../../models/caddy_config.dart';
import '../../models/config_node.dart';
import 'config_editor.dart';
import 'config_search_bar.dart';
import 'config_tree_view.dart';

class ConfigEditorPage extends StatefulWidget {
  final CaddyConfig config;
  final void Function(ConfigNode node, dynamic value) onConfigChanged;

  const ConfigEditorPage({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<ConfigEditorPage> createState() => _ConfigEditorPageState();
}

class _ConfigEditorPageState extends State<ConfigEditorPage> {
  late ConfigNode _root;
  ConfigNode? _selectedNode;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initializeRoot();
  }

  @override
  void didUpdateWidget(ConfigEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _initializeRoot();
    }
  }

  void _initializeRoot() {
    _root = ConfigNode.fromJson('root', widget.config.raw);
    _selectedNode = null;
    _isDirty = false;
  }

  void _handleSearch(String query) {
    print('🔍 Searching for: "$query"');
    final match = _root.findInSearch(query);
    if (match != null) {
      print('🔍 Found match: ${match.path}');
    } else {
      print('🔍 No match found');
    }

    setState(() {
      _root.applySearch(query, matchNode: match);
      if (match != null) {
        print('🔍 Setting selected node to: ${match.path}');
        _selectedNode = match;
      }
    });
  }

  void _handleNodeSelected(ConfigNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  void _handleNodeExpanded(ConfigNode node, bool expanded) {
    setState(() {
      node.isExpanded = expanded;
    });
  }

  void _handleValueChanged(ConfigNode node, dynamic value) {
    setState(() {
      node.updateValue(value);
      _isDirty = true;
    });
  }

  void _handleSave() {
    if (!_isDirty || _selectedNode == null) return;

    widget.onConfigChanged(_selectedNode!, _selectedNode!.value);
    setState(() => _isDirty = false);
  }

  void _handleCancel() {
    if (!_isDirty) return;

    setState(() {
      _initializeRoot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ConfigSearchBar(
            onSearch: _handleSearch,
            onClear: () => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use column layout for narrow screens
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.4,
                        child: ConfigTreeView(
                          root: _root,
                          onNodeSelected: _handleNodeSelected,
                          onNodeExpanded: _handleNodeExpanded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildEditor(),
                      ),
                    ],
                  );
                }

                // Use row layout for wider screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ConfigTreeView(
                        root: _root,
                        onNodeSelected: _handleNodeSelected,
                        onNodeExpanded: _handleNodeExpanded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _buildEditor(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    if (_selectedNode == null) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select a configuration item to edit',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ConfigEditor(
      key: ValueKey(_selectedNode!.path),
      node: _selectedNode!,
      onValueChanged: _handleValueChanged,
      onSave: _isDirty ? _handleSave : null,
      onCancel: _isDirty ? _handleCancel : null,
    );
  }
}
