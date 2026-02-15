import 'package:equatable/equatable.dart';

/// Technical comment translated to English.
class AppInfo extends Equatable {

  const AppInfo({
    required this.hostname,
    required this.git,
    required this.path,
    this.time,
  });
  final String hostname;
  final bool git;
  final AppPath path;
  final AppTime? time;

  @override
  List<Object?> get props => [hostname, git, path, time];
}

/// Technical comment translated to English.
class AppPath extends Equatable {

  const AppPath({
    required this.config,
    required this.data,
    required this.root,
    required this.cwd,
    required this.state,
  });
  final String config;
  final String data;
  final String root;
  final String cwd;
  final String state;

  @override
  List<Object> get props => [config, data, root, cwd, state];
}

/// Technical comment translated to English.
class AppTime extends Equatable {

  const AppTime({this.initialized});
  final int? initialized;

  @override
  List<Object?> get props => [initialized];
}
