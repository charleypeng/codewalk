part of '../chat_message_widget.dart';

/// Tool name resolution, label extraction, and presentation mapping.
extension _ChatMessageToolHelpers on _ChatMessageWidgetState {
  String _resolveToolDescriptionLabel(ToolPart part) {
    return toolResolveDescriptionLabel(part);
  }

  Map<String, dynamic>? _toolStateMetadata(ToolState state) {
    return toolStateMetadata(state);
  }

  Map<String, dynamic>? _toolStateInput(ToolState state) {
    return toolStateInput(state);
  }

  String? _extractPreferredToolLabel(
    Map<String, dynamic>? data, {
    int depth = 0,
  }) {
    return extractPreferredToolLabel(data, depth: depth);
  }

  String? _normalizeToolLabel(dynamic raw) {
    return normalizeToolLabel(raw);
  }

  String _resolveToolTypeLabel(ToolPart part) {
    return toolResolveTypeLabel(part);
  }

  _ToolPresentation _toolPresentation(String rawToolName) {
    final presentation = toolPresentation(rawToolName);
    return _ToolPresentation(
      title: presentation.title,
      subtitle: presentation.subtitle,
      icon: presentation.icon,
    );
  }

  String _normalizeToolName(String rawToolName) {
    return normalizeToolName(rawToolName);
  }

  String _humanizeToolName(String normalizedToolName) {
    return humanizeToolName(normalizedToolName);
  }
}

class _ToolPresentation {
  const _ToolPresentation({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
