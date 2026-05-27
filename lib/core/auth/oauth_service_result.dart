class OAuthFlowResult {
  final List<String> log;
  final String? error;
  final String? token;
  final bool needsConsent;

  OAuthFlowResult({
    this.log = const [],
    this.error,
    this.token,
    this.needsConsent = true,
  });

  bool get ok => error == null && token != null;
}
