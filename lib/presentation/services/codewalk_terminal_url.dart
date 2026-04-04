Uri buildCodewalkTerminalSocketUrl({
  required String baseUrl,
  required String ptyId,
  required String directory,
  int? cursor,
}) {
  final resolved = Uri.parse(baseUrl);
  final normalizedPath = resolved.path.replaceFirst(RegExp(r'/+$'), '');
  final pathPrefix = normalizedPath.isEmpty ? '' : normalizedPath;
  final scheme = resolved.scheme == 'https' ? 'wss' : 'ws';

  return resolved.replace(
    scheme: scheme,
    path: '$pathPrefix/pty/$ptyId/connect',
    queryParameters: <String, String>{
      'directory': directory,
      if (cursor != null) 'cursor': '$cursor',
    },
  );
}
