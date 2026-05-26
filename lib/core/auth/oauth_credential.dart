class OAuthCredential {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String serverUrl;
  final String? clientId;

  const OAuthCredential({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.serverUrl,
    this.clientId,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(
      expiresAt!.subtract(const Duration(minutes: 5)),
    );
  }

  bool get isValid => !isExpired && accessToken.isNotEmpty;

  factory OAuthCredential.fromJson(Map<String, dynamic> json) =>
      OAuthCredential(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
            : null,
        serverUrl: json['serverUrl'] as String,
        clientId: json['clientId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
    'serverUrl': serverUrl,
    'clientId': clientId,
  };
}
