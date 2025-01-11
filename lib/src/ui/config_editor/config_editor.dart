import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/config_node.dart';

class ConfigEditor extends StatefulWidget {
  final ConfigNode node;
  final void Function(ConfigNode node, dynamic value) onValueChanged;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const ConfigEditor({
    super.key,
    required this.node,
    required this.onValueChanged,
    this.onSave,
    this.onCancel,
  });

  @override
  State<ConfigEditor> createState() => _ConfigEditorState();
}

class _ConfigEditorState extends State<ConfigEditor> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _getInitialValue());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getInitialValue() {
    switch (widget.node.type) {
      case ConfigValueType.string:
        return widget.node.value?.toString() ?? '';
      case ConfigValueType.number:
        return widget.node.value?.toString() ?? '0';
      case ConfigValueType.boolean:
        return widget.node.value?.toString() ?? 'false';
      case ConfigValueType.array:
      case ConfigValueType.object:
        return const JsonEncoder.withIndent('  ')
            .convert(widget.node.value ?? {});
      case ConfigValueType.null_:
        return 'null';
    }
  }

  void _handleValueChanged(dynamic value) {
    setState(() => _error = null);
    widget.onValueChanged(widget.node, value);
  }

  void _validateAndUpdate(String text) {
    setState(() => _error = null);

    try {
      switch (widget.node.type) {
        case ConfigValueType.string:
          _handleValueChanged(text);
          break;

        case ConfigValueType.number:
          if (text.isEmpty) {
            setState(() => _error = 'Please enter a number');
            return;
          }
          final number = num.tryParse(text);
          if (number == null) {
            setState(() => _error = 'Please enter a valid number');
            return;
          }
          _handleValueChanged(number);
          break;

        case ConfigValueType.boolean:
          final value = text.toLowerCase();
          if (value != 'true' && value != 'false') {
            setState(() => _error = 'Please enter true or false');
            return;
          }
          _handleValueChanged(value == 'true');
          break;

        case ConfigValueType.array:
        case ConfigValueType.object:
          try {
            final value = json.decode(text);
            if (widget.node.type == ConfigValueType.array && value is! List) {
              setState(() => _error = 'Please enter a valid JSON array');
              return;
            }
            if (widget.node.type == ConfigValueType.object && value is! Map) {
              setState(() => _error = 'Please enter a valid JSON object');
              return;
            }
            _handleValueChanged(value);
          } catch (e) {
            setState(() => _error = 'Please enter valid JSON');
          }
          break;

        case ConfigValueType.null_:
          if (text.toLowerCase() != 'null') {
            setState(() => _error = 'Please enter null');
            return;
          }
          _handleValueChanged(null);
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.node.type.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.key,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.node.path,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.node.type.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.node.type == ConfigValueType.boolean)
              _buildBooleanEditor()
            else
              _buildTextEditor(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                if (widget.onSave != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _error == null ? widget.onSave : null,
                    child: const Text('Save'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooleanEditor() {
    return SwitchListTile(
      title: const Text('Value'),
      value: widget.node.value ?? false,
      onChanged: _handleValueChanged,
    );
  }

  Widget _buildTextEditor() {
    final maxLines = widget.node.type == ConfigValueType.string ? 1 : null;
    final minLines = widget.node.type == ConfigValueType.string ? 1 : 3;
    final style = widget.node.type == ConfigValueType.string
        ? null
        : const TextStyle(fontFamily: 'monospace');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Value',
          helperText: _getHelperText(),
          errorText: _error,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: maxLines,
        minLines: minLines,
        style: style,
        onChanged: _validateAndUpdate,
      ),
    );
  }

  String? _getHelperText() {
    switch (widget.node.type) {
      case ConfigValueType.string:
        return null;
      case ConfigValueType.number:
        return 'Enter a number';
      case ConfigValueType.boolean:
        return 'Enter true or false';
      case ConfigValueType.array:
        return 'Enter a JSON array';
      case ConfigValueType.object:
        return 'Enter a JSON object';
      case ConfigValueType.null_:
        return 'Enter null';
    }
  }
}
