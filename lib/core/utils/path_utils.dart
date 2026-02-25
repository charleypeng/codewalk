/// Normalizes a file path: trims whitespace, converts backslashes to forward
/// slashes, and strips trailing slashes (except for bare root "/").
String normalizeFilePath(String path) {
  var value = path.trim().replaceAll('\\', '/');
  if (value.isEmpty) {
    return value;
  }
  if (value.length > 1) {
    value = value.replaceAll(RegExp(r'/+$'), '');
  }
  return value;
}

/// Returns the base name (last path component) of a normalized path.
String fileBasename(String path) {
  final normalized = normalizeFilePath(path);
  if (normalized.isEmpty || normalized == '/') {
    return normalized.isEmpty ? 'file' : '/';
  }
  final separator = normalized.lastIndexOf('/');
  if (separator < 0 || separator == normalized.length - 1) {
    return normalized;
  }
  return normalized.substring(separator + 1);
}

/// Joins a parent path with a child path segment using a forward slash,
/// returning child unchanged when parent is empty, root, or ".".
String joinParentPath(String parent, String child) {
  if (parent.isEmpty || parent == '/' || parent == '.') {
    return child;
  }
  return '$parent/$child';
}
