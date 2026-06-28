import 'project_icon_discovery_service_base.dart';
import 'project_icon_discovery_service_stub.dart'
    if (dart.library.io) 'project_icon_discovery_service_io.dart' as impl;

ProjectIconDiscoveryService createProjectIconDiscoveryService() =>
    impl.createProjectIconDiscoveryService();
