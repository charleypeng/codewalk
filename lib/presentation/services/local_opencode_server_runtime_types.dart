abstract class LocalOpencodeServerRuntime {
  bool get isSupported;
  bool get isRunning;
  Stream<String> get stdoutLines;
  Stream<String> get stderrLines;
  Stream<int> get exitCodes;

  Future<LocalOpencodeServerStartResult> start({
    required String host,
    required int port,
    String? commandPath,
  });

  Future<LocalOpencodeEnvironmentReport> diagnose({String? commandPath});

  Future<LocalOpencodeInstallResult> install({
    required LocalOpencodeInstallMethod method,
    void Function(String line)? onLog,
  });

  Future<void> stop();
  Future<void> dispose();
}

enum LocalOpencodeInstallMethod {
  downloadBinary,
  npmGlobal,
  bunGlobal,
  bunBootstrapThenInstall,
}

class LocalToolStatus {
  const LocalToolStatus({
    required this.available,
    this.path = '',
    this.version = '',
    this.note = '',
  });

  final bool available;
  final String path;
  final String version;
  final String note;
}

class LocalOpencodeEnvironmentReport {
  const LocalOpencodeEnvironmentReport({
    required this.supported,
    required this.platform,
    required this.opencode,
    required this.node,
    required this.npm,
    required this.bun,
    required this.wsl,
    required this.hasNetworkAccess,
    required this.installDirectoryWritable,
    required this.recommendation,
  });

  final bool supported;
  final String platform;
  final LocalToolStatus opencode;
  final LocalToolStatus node;
  final LocalToolStatus npm;
  final LocalToolStatus bun;
  final LocalToolStatus wsl;
  final bool hasNetworkAccess;
  final bool installDirectoryWritable;
  final String recommendation;
}

class LocalOpencodeServerStartResult {
  const LocalOpencodeServerStartResult({required this.ok, this.errorMessage});

  final bool ok;
  final String? errorMessage;
}

class LocalOpencodeInstallResult {
  const LocalOpencodeInstallResult({
    required this.ok,
    this.errorMessage,
    this.commandPath,
  });

  final bool ok;
  final String? errorMessage;
  final String? commandPath;
}
