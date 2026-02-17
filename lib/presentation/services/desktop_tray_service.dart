import 'desktop_tray_service_stub.dart'
    if (dart.library.io) 'desktop_tray_service_io.dart'
    as impl;
import 'desktop_tray_service_types.dart';

DesktopTrayService createDesktopTrayService() {
  return impl.createDesktopTrayService();
}
