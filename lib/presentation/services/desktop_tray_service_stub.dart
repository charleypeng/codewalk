import 'desktop_tray_service_types.dart';

DesktopTrayService createDesktopTrayService() {
  return _DesktopTrayServiceStub();
}

class _DesktopTrayServiceStub implements DesktopTrayService {
  @override
  bool get supported => false;

  @override
  Future<void> initialize({required bool closeToTrayEnabled}) async {}

  @override
  Future<void> setCloseToTrayEnabled(bool enabled) async {}

  @override
  Future<void> dispose() async {}
}
