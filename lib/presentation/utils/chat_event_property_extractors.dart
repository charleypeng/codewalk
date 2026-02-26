String? extractEventSessionId(Map<String, dynamic> properties) {
  final direct = _readTrimmed(properties, 'sessionID');
  if (direct != null) {
    return direct;
  }

  final info = properties['info'];
  if (info is Map) {
    final nestedSessionId = _readTrimmed(info, 'sessionID');
    if (nestedSessionId != null) {
      return nestedSessionId;
    }
    return _readTrimmed(info, 'id');
  }

  return null;
}

String? extractEventDirectory(Map<String, dynamic> properties) {
  final direct = _readTrimmed(properties, 'directory');
  if (direct != null) {
    return direct;
  }

  final info = properties['info'];
  if (info is Map) {
    final nested = _readTrimmed(info, 'directory');
    if (nested != null) {
      return nested;
    }
  }

  final session = properties['session'];
  if (session is Map) {
    final nested = _readTrimmed(session, 'directory');
    if (nested != null) {
      return nested;
    }
  }

  final project = properties['project'];
  if (project is Map) {
    final nested = _readTrimmed(project, 'directory');
    if (nested != null) {
      return nested;
    }
  }

  return null;
}

String? _readTrimmed(Map<dynamic, dynamic> source, String key) {
  final value = source[key]?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}
