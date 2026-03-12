import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/chat_message.dart';

class ToolPresentationData {
  const ToolPresentationData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

final RegExp _toolWhitespaceRegExp = RegExp(r'\s+');

String toolResolveDescriptionLabel(ToolPart part) {
  final explicitTitle = switch (part.state.status) {
    ToolStatus.running => (part.state as ToolStateRunning).title,
    ToolStatus.completed => (part.state as ToolStateCompleted).title,
    ToolStatus.error => (part.state as ToolStateError).title,
    ToolStatus.pending => null,
  };

  final candidateLabels = <String?>[
    explicitTitle,
    extractPreferredToolLabel(toolStateMetadata(part.state)),
    extractPreferredToolLabel(toolStateInput(part.state)),
  ];
  for (final candidate in candidateLabels) {
    final normalized = normalizeToolLabel(candidate);
    if (normalized != null) {
      return normalized;
    }
  }

  return toolPresentation(part.tool).title;
}

Map<String, dynamic>? toolStateMetadata(ToolState state) {
  return switch (state.status) {
    ToolStatus.running => (state as ToolStateRunning).metadata,
    ToolStatus.completed => (state as ToolStateCompleted).metadata,
    ToolStatus.error => (state as ToolStateError).metadata,
    ToolStatus.pending => null,
  };
}

Map<String, dynamic>? toolStateInput(ToolState state) {
  return switch (state.status) {
    ToolStatus.running => (state as ToolStateRunning).input,
    ToolStatus.completed => (state as ToolStateCompleted).input,
    ToolStatus.error => (state as ToolStateError).input,
    ToolStatus.pending => null,
  };
}

String? extractPreferredToolLabel(Map<String, dynamic>? data, {int depth = 0}) {
  if (data == null || data.isEmpty || depth > 1) {
    return null;
  }

  const preferredKeys = <String>[
    'description',
    'title',
    'label',
    'summary',
    'caption',
    'task',
    'intent',
    'purpose',
    'message',
  ];
  for (final key in preferredKeys) {
    final normalized = normalizeToolLabel(data[key]);
    if (normalized != null) {
      return normalized;
    }
  }

  const nestedKeys = <String>['metadata', 'meta', 'tool', 'state', 'ui'];
  for (final key in nestedKeys) {
    final nested = data[key];
    if (nested is! Map) {
      continue;
    }
    final nestedMap = <String, dynamic>{};
    for (final entry in nested.entries) {
      final nestedKey = entry.key;
      if (nestedKey is! String) {
        continue;
      }
      nestedMap[nestedKey] = entry.value;
    }
    if (nestedMap.isEmpty) {
      continue;
    }
    final nestedLabel = extractPreferredToolLabel(nestedMap, depth: depth + 1);
    if (nestedLabel != null) {
      return nestedLabel;
    }
  }

  return null;
}

String? normalizeToolLabel(dynamic raw) {
  if (raw is! String) {
    return null;
  }
  final normalized = raw.replaceAll(_toolWhitespaceRegExp, ' ').trim();
  if (normalized.isEmpty) {
    return null;
  }
  const maxLabelLength = 120;
  if (normalized.length <= maxLabelLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLabelLength - 1)}…';
}

String toolResolveTypeLabel(ToolPart part) {
  return toolPresentation(part.tool).title;
}

ToolPresentationData toolPresentation(String rawToolName) {
  final normalized = normalizeToolName(rawToolName);
  switch (normalized) {
    case 'bash':
    case 'shell':
      return ToolPresentationData(
        title: 'Running command',
        subtitle: rawToolName,
        icon: Symbols.terminal_rounded,
      );
    case 'read':
      return ToolPresentationData(
        title: 'Reading file',
        subtitle: rawToolName,
        icon: Symbols.description,
      );
    case 'write':
      return ToolPresentationData(
        title: 'Writing file',
        subtitle: rawToolName,
        icon: Symbols.edit_note_rounded,
      );
    case 'edit':
    case 'apply_patch':
    case 'patch':
      return ToolPresentationData(
        title: 'Editing files',
        subtitle: rawToolName,
        icon: Symbols.auto_fix_high_rounded,
      );
    case 'glob':
    case 'find':
      return ToolPresentationData(
        title: 'Finding files',
        subtitle: rawToolName,
        icon: Symbols.folder_open,
      );
    case 'grep':
      return ToolPresentationData(
        title: 'Searching code',
        subtitle: rawToolName,
        icon: Symbols.search_rounded,
      );
    case 'webfetch':
    case 'google_search':
    case 'brave_web_search':
    case 'brave_news_search':
    case 'brave_video_search':
    case 'brave_image_search':
    case 'brave_local_search':
      return ToolPresentationData(
        title: 'Searching the web',
        subtitle: rawToolName,
        icon: Symbols.travel_explore_rounded,
      );
    case 'question':
      return ToolPresentationData(
        title: 'Waiting for your input',
        subtitle: rawToolName,
        icon: Symbols.help_outline_rounded,
      );
    case 'todowrite':
    case 'todoread':
      return ToolPresentationData(
        title: 'Updating task list',
        subtitle: rawToolName,
        icon: Symbols.checklist_rounded,
      );
    default:
      return ToolPresentationData(
        title: 'Running ${humanizeToolName(normalized)}',
        subtitle: rawToolName,
        icon: Symbols.extension,
      );
  }
}

String normalizeToolName(String rawToolName) {
  final normalized = rawToolName.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'tool';
  }
  final separatorIndex = normalized.lastIndexOf('.');
  final compactName = separatorIndex >= 0
      ? normalized.substring(separatorIndex + 1)
      : normalized;
  return compactName.replaceAll('-', '_');
}

String humanizeToolName(String normalizedToolName) {
  final words = normalizedToolName
      .split('_')
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) {
        final trimmed = segment.trim();
        return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
      })
      .toList(growable: false);
  if (words.isEmpty) {
    return 'Tool';
  }
  return words.join(' ');
}
