import '../../domain/entities/experience_settings.dart';

abstract class DesktopTrayService {
  bool get supported;

  Future<void> initialize({required DesktopCloseBehavior closeBehavior});

  Future<void> setDesktopCloseBehavior(DesktopCloseBehavior behavior);

  Future<void> dispose();
}
