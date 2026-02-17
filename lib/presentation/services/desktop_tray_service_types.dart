abstract class DesktopTrayService {
  bool get supported;

  Future<void> initialize({required bool closeToTrayEnabled});

  Future<void> setCloseToTrayEnabled(bool enabled);

  Future<void> dispose();
}
