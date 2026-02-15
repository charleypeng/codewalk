import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/session.dart';

part 'session_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SessionModel extends Session {

  const SessionModel({
    required super.id,
    super.parentId,
    required super.title,
    required super.version,
    required this.time,
    this.share,
    this.revert,
  }) : parentIdField = parentId,
       super(
         time: time,
         share: share,
         revert: revert,
       );

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
  @JsonKey(name: 'parentID')
  final String? parentIdField;

  @override
  @JsonKey(name: 'time')
  final SessionTimeModel time;

  @override
  @JsonKey(name: 'share')
  final SessionShareModel? share;

  @override
  @JsonKey(name: 'revert')
  final SessionRevertModel? revert;

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);

  Session toEntity() => Session(
    id: id,
    parentId: parentId,
    title: title,
    version: version,
    time: time,
    share: share,
    revert: revert,
  );
}

@JsonSerializable()
class SessionTimeModel extends SessionTime {
  const SessionTimeModel({required super.created, required super.updated});

  factory SessionTimeModel.fromJson(Map<String, dynamic> json) =>
      _$SessionTimeModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionTimeModelToJson(this);
}

@JsonSerializable()
class SessionShareModel extends SessionShare {
  const SessionShareModel({required super.url});

  factory SessionShareModel.fromJson(Map<String, dynamic> json) =>
      _$SessionShareModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionShareModelToJson(this);
}

@JsonSerializable()
class SessionRevertModel extends SessionRevert {

  const SessionRevertModel({
    required super.messageId,
    super.partId,
    super.snapshot,
    super.diff,
  }) : messageIdField = messageId,
       partIdField = partId;

  factory SessionRevertModel.fromJson(Map<String, dynamic> json) =>
      _$SessionRevertModelFromJson(json);
  @JsonKey(name: 'messageID')
  final String messageIdField;
  @JsonKey(name: 'partID')
  final String? partIdField;

  Map<String, dynamic> toJson() => _$SessionRevertModelToJson(this);
}
