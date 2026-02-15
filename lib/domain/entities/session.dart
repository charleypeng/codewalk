import 'package:equatable/equatable.dart';

/// Technical comment translated to English.
class Session extends Equatable {

  const Session({
    required this.id,
    this.parentId,
    required this.title,
    required this.version,
    required this.time,
    this.share,
    this.revert,
  });
  final String id;
  final String? parentId;
  final String title;
  final String version;
  final SessionTime time;
  final SessionShare? share;
  final SessionRevert? revert;

  @override
  List<Object?> get props => [
    id,
    parentId,
    title,
    version,
    time,
    share,
    revert,
  ];
}

/// Technical comment translated to English.
class SessionTime extends Equatable {

  const SessionTime({required this.created, required this.updated});
  final int created;
  final int updated;

  @override
  List<Object> get props => [created, updated];
}

/// Technical comment translated to English.
class SessionShare extends Equatable {

  const SessionShare({required this.url});
  final String url;

  @override
  List<Object> get props => [url];
}

/// Technical comment translated to English.
class SessionRevert extends Equatable {

  const SessionRevert({
    required this.messageId,
    this.partId,
    this.snapshot,
    this.diff,
  });
  final String messageId;
  final String? partId;
  final String? snapshot;
  final String? diff;

  @override
  List<Object?> get props => [messageId, partId, snapshot, diff];
}
