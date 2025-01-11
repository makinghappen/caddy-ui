import 'dart:convert';
import 'package:flutter/material.dart';

enum ConfigValueType {
  string,
  number,
  boolean,
  array,
  object,
  null_;

  static ConfigValueType fromValue(dynamic value) {
    if (value == null) return ConfigValueType.null_;
    if (value is String) return ConfigValueType.string;
    if (value is num) return ConfigValueType.number;
    if (value is bool) return ConfigValueType.boolean;
    if (value is List) return ConfigValueType.array;
    if (value is Map) return ConfigValueType.object;
    return ConfigValueType.string; // Default to string for unknown types
  }

  IconData get icon {
    switch (this) {
      case ConfigValueType.string:
        return Icons.text_fields;
      case ConfigValueType.number:
        return Icons.numbers;
      case ConfigValueType.boolean:
        return Icons.toggle_on;
      case ConfigValueType.array:
        return Icons.list;
      case ConfigValueType.object:
        return Icons.folder;
      case ConfigValueType.null_:
        return Icons.block;
    }
  }

  String get label {
    switch (this) {
      case ConfigValueType.string:
        return 'Text';
      case ConfigValueType.number:
        return 'Number';
      case ConfigValueType.boolean:
        return 'Boolean';
      case ConfigValueType.array:
        return 'Array';
      case ConfigValueType.object:
        return 'Object';
      case ConfigValueType.null_:
        return 'Null';
    }
  }
}

class ConfigNode {
  final String key;
  final String path;
  dynamic value;
  final ConfigValueType type;
  final List<ConfigNode> children;
  bool isExpanded;
  bool isVisible;
  bool isEditing;

  ConfigNode({
    required this.key,
    required this.path,
    required this.value,
    List<ConfigNode>? children,
    this.isExpanded = false,
    this.isVisible = true,
    this.isEditing = false,
  })  : type = ConfigValueType.fromValue(value),
        children = children ?? [];

  factory ConfigNode.fromJson(
    String key,
    dynamic value, {
    String parentPath = '',
  }) {
    final path = parentPath.isEmpty ? key : '$parentPath.$key';

    if (value is Map) {
      final children = value.entries
          .map((e) => ConfigNode.fromJson(
                e.key.toString(),
                e.value,
                parentPath: path,
              ))
          .toList();
      return ConfigNode(
        key: key,
        path: path,
        value: value,
        children: children,
      );
    }

    if (value is List) {
      final children = List.generate(
        value.length,
        (i) => ConfigNode.fromJson(
          i.toString(),
          value[i],
          parentPath: path,
        ),
      );
      return ConfigNode(
        key: key,
        path: path,
        value: value,
        children: children,
      );
    }

    return ConfigNode(
      key: key,
      path: path,
      value: value,
    );
  }

  Map<String, dynamic> toJson() {
    if (children.isEmpty) return {key: value};

    if (type == ConfigValueType.array) {
      final list = List.generate(
        children.length,
        (i) => children[i].value,
      );
      return {key: list};
    }

    final map = <String, dynamic>{};
    for (final child in children) {
      map.addAll(child.toJson());
    }
    return {key: map};
  }

  void updateValue(dynamic newValue) {
    value = newValue;
    // If type changed, clear children
    final newType = ConfigValueType.fromValue(newValue);
    if (newType != type &&
        newType != ConfigValueType.object &&
        newType != ConfigValueType.array) {
      children.clear();
    }
  }

  ConfigNode? findInSearch(String query) {
    if (query.isEmpty) return null;

    final q = query.toLowerCase();
    print('🔍 Searching in node: $path');

    // First search all children recursively
    for (final child in children) {
      final match = child.findInSearch(query);
      if (match != null) {
        print('🔍 Found match in child: ${match.path}');
        return match;
      }
    }

    // Then check this node (skip root)
    if (key != 'root') {
      // Check key
      if (key.toLowerCase().contains(q)) {
        print('🔍 Found match in key: $key');
        return this;
      }

      // Only check primitive values
      if (type != ConfigValueType.object && type != ConfigValueType.array) {
        final valueStr = value?.toString().toLowerCase() ?? '';
        if (valueStr.contains(q)) {
          print('🔍 Found match in value: $valueStr at node: $path');
          return this;
        }
      }
    }

    // If no direct matches found, try searching in stringified JSON for objects/arrays
    if (type == ConfigValueType.object || type == ConfigValueType.array) {
      // Convert to JSON and remove all whitespace for comparison
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(value)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '');
      final queryNoSpace = q.replaceAll(RegExp(r'\s+'), '');

      if (jsonStr.contains(queryNoSpace)) {
        print('🔍 Found match in JSON content: $path');
        return this;
      }
    }

    print('🔍 No match found in: $path');
    return null;
  }

  void applySearch(String query, {ConfigNode? matchNode}) {
    print('🔍 Applying search in node: $path');
    print('🔍 Match node: ${matchNode?.path}');

    if (query.isEmpty) {
      print('🔍 Empty query, resetting node: $path');
      // Reset all nodes to visible and collapsed
      isVisible = true;
      isExpanded = false;
      for (final child in children) {
        child.applySearch('');
      }
      return;
    }

    if (matchNode == null) {
      print('🔍 No match, hiding node: $path');
      // No match, hide everything except root
      isVisible = key == 'root';
      isExpanded = key == 'root';
      for (final child in children) {
        child.applySearch(query);
      }
      return;
    }

    // Handle match case
    if (this == matchNode) {
      print('🔍 This is the matching node: $path');
      // This is the matching node
      isVisible = true;
      isExpanded = children.isNotEmpty;
      // Show children but keep them collapsed
      for (final child in children) {
        child.isVisible = true;
        child.isExpanded = false;
      }
    } else if (isAncestorOf(matchNode)) {
      print('🔍 This is an ancestor of match: $path');
      // This is an ancestor of the match
      isVisible = true;
      isExpanded = true;
      // Continue search in children
      for (final child in children) {
        child.applySearch(query, matchNode: matchNode);
      }
    } else if (isDescendantOf(matchNode)) {
      print('🔍 This is a descendant of match: $path');
      // This is a descendant of the match
      isVisible = true;
      isExpanded = false;
    } else {
      print('🔍 Unrelated node, hiding: $path');
      // Unrelated node - keep root visible but hide others
      isVisible = key == 'root';
      isExpanded = key == 'root';
    }
  }

  bool isAncestorOf(ConfigNode node) {
    final parts = node.path.split('.');
    final myParts = path.split('.');
    if (myParts.length >= parts.length) return false;
    return parts.take(myParts.length).join('.') == path;
  }

  bool isDescendantOf(ConfigNode node) {
    final parts = path.split('.');
    final parentParts = node.path.split('.');
    if (parentParts.length >= parts.length) return false;
    return parts.take(parentParts.length).join('.') == node.path;
  }

  ConfigNode copyWith({
    String? key,
    String? path,
    dynamic value,
    List<ConfigNode>? children,
    bool? isExpanded,
    bool? isVisible,
    bool? isEditing,
  }) {
    return ConfigNode(
      key: key ?? this.key,
      path: path ?? this.path,
      value: value ?? this.value,
      children: children ?? List.from(this.children),
      isExpanded: isExpanded ?? this.isExpanded,
      isVisible: isVisible ?? this.isVisible,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  String toString() =>
      'ConfigNode(key: $key, path: $path, type: $type, value: $value)';
}
