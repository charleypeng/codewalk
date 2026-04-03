enum CannedAnswerInsertMode { append, replace }

enum CannedAnswerScopeMode { global, projectOnly }

class CannedAnswer {
  const CannedAnswer({
    required this.id,
    required this.text,
    this.label,
    this.insertMode = CannedAnswerInsertMode.append,
    this.sendAutomatically = false,
    this.scopeMode = CannedAnswerScopeMode.global,
    required this.updatedAtEpochMs,
  });

  final String id;
  final String text;
  final String? label;
  final CannedAnswerInsertMode insertMode;
  final bool sendAutomatically;
  final CannedAnswerScopeMode scopeMode;
  final int updatedAtEpochMs;

  String get normalizedLabel {
    final trimmed = label?.trim() ?? '';
    return trimmed;
  }

  CannedAnswer copyWith({
    String? id,
    String? text,
    String? Function()? label,
    CannedAnswerInsertMode? insertMode,
    bool? sendAutomatically,
    CannedAnswerScopeMode? scopeMode,
    int? updatedAtEpochMs,
  }) {
    return CannedAnswer(
      id: id ?? this.id,
      text: text ?? this.text,
      label: label != null ? label() : this.label,
      insertMode: insertMode ?? this.insertMode,
      sendAutomatically: sendAutomatically ?? this.sendAutomatically,
      scopeMode: scopeMode ?? this.scopeMode,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      if (normalizedLabel.isNotEmpty) 'label': normalizedLabel,
      'insertMode': _insertModeKey(insertMode),
      if (sendAutomatically) 'sendAutomatically': true,
      'scopeMode': _scopeModeKey(scopeMode),
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static CannedAnswer? fromJson(Map<dynamic, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final text = json['text']?.toString() ?? '';
    if (id.isEmpty || text.trim().isEmpty) {
      return null;
    }
    final label = json['label']?.toString();
    final modeValue = json['insertMode']?.toString().trim().toLowerCase() ?? '';
    final sendAutomatically = json['sendAutomatically'] == true;
    final scopeValue = json['scopeMode']?.toString().trim().toLowerCase() ?? '';
    final updatedAtRaw = json['updatedAtEpochMs'];
    final updatedAtEpochMs = updatedAtRaw is num
        ? updatedAtRaw.toInt()
        : DateTime.now().millisecondsSinceEpoch;
    return CannedAnswer(
      id: id,
      text: text,
      label: label,
      insertMode: _insertModeFromKey(modeValue),
      sendAutomatically: sendAutomatically,
      scopeMode: _scopeModeFromKey(scopeValue),
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }
}

String _insertModeKey(CannedAnswerInsertMode mode) {
  return switch (mode) {
    CannedAnswerInsertMode.append => 'append',
    CannedAnswerInsertMode.replace => 'replace',
  };
}

CannedAnswerInsertMode _insertModeFromKey(String value) {
  return switch (value) {
    'replace' => CannedAnswerInsertMode.replace,
    _ => CannedAnswerInsertMode.append,
  };
}

String _scopeModeKey(CannedAnswerScopeMode mode) {
  return switch (mode) {
    CannedAnswerScopeMode.global => 'global',
    CannedAnswerScopeMode.projectOnly => 'project_only',
  };
}

CannedAnswerScopeMode _scopeModeFromKey(String value) {
  return switch (value) {
    'project_only' => CannedAnswerScopeMode.projectOnly,
    _ => CannedAnswerScopeMode.global,
  };
}
