import '../../domain/entities/chat_realtime.dart';

String permissionAutoApproveReplyForAlwaysPatterns(
  Iterable<String> alwaysPatterns,
) {
  for (final pattern in alwaysPatterns) {
    if (pattern.trim().isNotEmpty) {
      return 'always';
    }
  }
  return 'once';
}

String permissionAutoApproveReplyForRequest(ChatPermissionRequest request) {
  return permissionAutoApproveReplyForAlwaysPatterns(request.always);
}

class PermissionAutoApproveBackgroundContext {
  const PermissionAutoApproveBackgroundContext({
    required this.serverId,
    required this.scopeId,
    required this.currentSessionId,
    required this.threadSessionIds,
    required this.updatedAtEpochMs,
    this.directory,
  });

  factory PermissionAutoApproveBackgroundContext.fromJson(
    Map<String, dynamic> json,
  ) {
    List<String> parseSessionIds(dynamic raw) {
      if (raw is! List) {
        return const <String>[];
      }
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    return PermissionAutoApproveBackgroundContext(
      serverId: json['serverId']?.toString().trim() ?? '',
      scopeId: json['scopeId']?.toString().trim() ?? '',
      currentSessionId: json['currentSessionId']?.toString().trim() ?? '',
      threadSessionIds: parseSessionIds(json['threadSessionIds']),
      updatedAtEpochMs: json['updatedAtEpochMs'] is num
          ? (json['updatedAtEpochMs'] as num).toInt()
          : 0,
      directory: json['directory'] is String
          ? (json['directory'] as String).trim()
          : null,
    );
  }

  final String serverId;
  final String scopeId;
  final String currentSessionId;
  final List<String> threadSessionIds;
  final int updatedAtEpochMs;
  final String? directory;

  bool get isValid {
    return serverId.isNotEmpty &&
        scopeId.isNotEmpty &&
        currentSessionId.isNotEmpty &&
        threadSessionIds.isNotEmpty;
  }

  String get signature {
    final normalizedDirectory = directory?.trim() ?? '';
    final normalizedThreadIds = List<String>.from(threadSessionIds)
      ..sort((left, right) => left.compareTo(right));
    return '$serverId|$scopeId|$currentSessionId|$normalizedDirectory|${normalizedThreadIds.join(',')}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'serverId': serverId,
      'scopeId': scopeId,
      'currentSessionId': currentSessionId,
      'threadSessionIds': threadSessionIds,
      'updatedAtEpochMs': updatedAtEpochMs,
      if (directory != null && directory!.trim().isNotEmpty)
        'directory': directory!.trim(),
    };
  }
}

Set<String> collectThreadSessionIds({
  required String currentSessionId,
  required Map<String, String> parentSessionIdByChild,
}) {
  final normalizedCurrentSessionId = currentSessionId.trim();
  if (normalizedCurrentSessionId.isEmpty) {
    return const <String>{};
  }

  final output = <String>{normalizedCurrentSessionId};
  var keepWalking = true;
  while (keepWalking) {
    keepWalking = false;
    for (final entry in parentSessionIdByChild.entries) {
      final childId = entry.key.trim();
      final parentId = entry.value.trim();
      if (childId.isEmpty || parentId.isEmpty || output.contains(childId)) {
        continue;
      }
      if (output.contains(parentId)) {
        output.add(childId);
        keepWalking = true;
      }
    }
  }

  return output;
}

Set<String> resolveThreadSessionIdsForBackgroundContext({
  required PermissionAutoApproveBackgroundContext context,
  required Map<String, String> parentSessionIdByChild,
}) {
  final output = <String>{
    context.currentSessionId.trim(),
    ...context.threadSessionIds.map((item) => item.trim()),
  }..removeWhere((item) => item.isEmpty);
  output.addAll(
    collectThreadSessionIds(
      currentSessionId: context.currentSessionId,
      parentSessionIdByChild: parentSessionIdByChild,
    ),
  );
  return output;
}
