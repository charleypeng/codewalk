import '../../domain/entities/experience_settings.dart';
import 'desktop_tray_service_types.dart';

DesktopTrayService createDesktopTrayService() {
  return _DesktopTrayServiceStub();
}

class _DesktopTrayServiceStub implements DesktopTrayService {
  @override
  bool get supported => false;

  @override
  Future<void> initialize({
    required DesktopCloseBehavior closeBehavior,
  }) async {}

  @override
  Future<void> setDesktopCloseBehavior(DesktopCloseBehavior behavior) async {}

  @override
  Future<void> dispose() async {}
}
