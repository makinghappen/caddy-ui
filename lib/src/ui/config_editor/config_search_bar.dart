import 'package:flutter/material.dart';

class ConfigSearchBar extends StatefulWidget {
  final void Function(String query) onSearch;
  final VoidCallback? onClear;

  const ConfigSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
  });

  @override
  State<ConfigSearchBar> createState() => _ConfigSearchBarState();
}

class _ConfigSearchBarState extends State<ConfigSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onSearch('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Search configuration...',
                  border: InputBorder.none,
                ),
                onChanged: widget.onSearch,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _handleClear,
                tooltip: 'Clear search',
              ),
          ],
        ),
      ),
    );
  }
}
