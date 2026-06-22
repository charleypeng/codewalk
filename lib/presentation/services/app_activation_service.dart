import 'app_activation_service_stub.dart'
    if (dart.library.io) 'app_activation_service_io.dart'
    if (dart.library.html) 'app_activation_service_web.dart'
    as impl;

Future<void> bringCodeWalkToFront() => impl.bringCodeWalkToFront();
