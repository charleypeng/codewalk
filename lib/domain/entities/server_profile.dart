import 'package:equatable/equatable.dart';

class ServerProfile extends Equatable {
  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
      basicAuthEnabled: json['basicAuthEnabled'] as bool? ?? false,
      basicAuthUsername: json['basicAuthUsername'] as String? ?? '',
      basicAuthPassword: json['basicAuthPassword'] as String? ?? '',
      oauthEnabled: json['oauthEnabled'] as bool? ?? false,
      tailscaleEnabled: json['tailscaleEnabled'] as bool? ?? false,
      aiGeneratedTitlesEnabled:
          json['aiGeneratedTitlesEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }
  const ServerProfile({
    required this.id,
    required this.url,
    this.label,
    this.basicAuthEnabled = false,
    this.basicAuthUsername = '',
    this.basicAuthPassword = '',
    this.oauthEnabled = false,
    this.tailscaleEnabled = false,
    this.aiGeneratedTitlesEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String url;
  final String? label;
  final bool basicAuthEnabled;
  final String basicAuthUsername;
  final String basicAuthPassword;
  final bool oauthEnabled;
  final bool tailscaleEnabled;
  final bool aiGeneratedTitlesEnabled;
  final int createdAt;
  final int updatedAt;

  String get displayName {
    final custom = label?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return url;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'label': label,
      'basicAuthEnabled': basicAuthEnabled,
      'basicAuthUsername': basicAuthUsername,
      'basicAuthPassword': basicAuthPassword,
      'oauthEnabled': oauthEnabled,
      'tailscaleEnabled': tailscaleEnabled,
      'aiGeneratedTitlesEnabled': aiGeneratedTitlesEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ServerProfile copyWith({
    String? id,
    String? url,
    String? label,
    bool? basicAuthEnabled,
    String? basicAuthUsername,
    String? basicAuthPassword,
    bool? oauthEnabled,
    bool? tailscaleEnabled,
    bool? aiGeneratedTitlesEnabled,
    int? createdAt,
    int? updatedAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      url: url ?? this.url,
      label: label ?? this.label,
      basicAuthEnabled: basicAuthEnabled ?? this.basicAuthEnabled,
      basicAuthUsername: basicAuthUsername ?? this.basicAuthUsername,
      basicAuthPassword: basicAuthPassword ?? this.basicAuthPassword,
      oauthEnabled: oauthEnabled ?? this.oauthEnabled,
      tailscaleEnabled: tailscaleEnabled ?? this.tailscaleEnabled,
      aiGeneratedTitlesEnabled:
          aiGeneratedTitlesEnabled ?? this.aiGeneratedTitlesEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    url,
    label,
    basicAuthEnabled,
    basicAuthUsername,
    basicAuthPassword,
    oauthEnabled,
    tailscaleEnabled,
    aiGeneratedTitlesEnabled,
    createdAt,
    updatedAt,
  ];
}
