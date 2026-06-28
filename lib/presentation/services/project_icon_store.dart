import 'project_icon_store_base.dart';
import 'project_icon_store_stub.dart'
    if (dart.library.io) 'project_icon_store_io.dart' as impl;

ProjectIconStore createProjectIconStore() => impl.createProjectIconStore();
