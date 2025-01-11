import 'package:flutter/material.dart';
import '../../models/config_node.dart';

class ConfigTreeView extends StatefulWidget {
  final ConfigNode root;
  final void Function(ConfigNode node) onNodeSelected;
  final void Function(ConfigNode node, bool expanded) onNodeExpanded;

  const ConfigTreeView({
    super.key,
    required this.root,
    required this.onNodeSelected,
    required this.onNodeExpanded,
  });

  @override
  State<ConfigTreeView> createState() => _ConfigTreeViewState();
}

class _ConfigTreeViewState extends State<ConfigTreeView> {
  final _scrollController = ScrollController();
  ConfigNode? _lastSelectedNode;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNodeSelected(ConfigNode node) {
    widget.onNodeSelected(node);
    _lastSelectedNode = node;
    // Schedule scroll after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedNode();
    });
  }

  void _scrollToSelectedNode() {
    if (_lastSelectedNode == null) return;

    // Find all node widgets
    final context = _getNodeContext(_lastSelectedNode!.path);
    if (context == null) return;

    // Get the render box
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Get position
    final position = box.localToGlobal(Offset.zero);
    final scrollOffset = position.dy;

    // Scroll to position
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  BuildContext? _getNodeContext(String path) {
    BuildContext? nodeContext;
    void visitor(Element element) {
      final widget = element.widget;
      if (widget is _TreeNode && widget.node.path == path) {
        nodeContext = element;
        return;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return nodeContext;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Tree',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildTree(widget.root),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTree(ConfigNode node) {
    if (!node.isVisible) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TreeNode(
          node: node,
          isSelected: node == _lastSelectedNode,
          onSelected: _handleNodeSelected,
          onExpanded: widget.onNodeExpanded,
        ),
        if (node.isExpanded && node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: node.children.map(_buildTree).toList(),
            ),
          ),
      ],
    );
  }
}

class _TreeNode extends StatelessWidget {
  final ConfigNode node;
  final bool isSelected;
  final void Function(ConfigNode node) onSelected;
  final void Function(ConfigNode node, bool expanded) onExpanded;

  const _TreeNode({
    required this.node,
    required this.isSelected,
    required this.onSelected,
    required this.onExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => onSelected(node),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              if (node.children.isNotEmpty)
                IconButton(
                  icon: Icon(
                    node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                  ),
                  onPressed: () => onExpanded(node, !node.isExpanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                )
              else
                const SizedBox(width: 32),
              Icon(node.type.icon),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (node.type != ConfigValueType.object &&
                        node.type != ConfigValueType.array)
                      Text(
                        node.value?.toString() ?? 'null',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  node.type.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
