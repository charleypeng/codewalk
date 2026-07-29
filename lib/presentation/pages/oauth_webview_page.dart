import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/navigation/app_navigator.dart';

/// Full-screen in-app WebView that runs the Cloudflare Access OAuth consent
/// flow (login, OTP, Allow).
///
/// Cloudflare Managed OAuth DCR only accepts loopback redirect URIs, but a
/// real loopback HTTP round-trip from a browser is fragile on Android
/// (backgrounding, callback-server lifetime races). This page instead
/// *intercepts* the navigation to the registered loopback callback URI and
/// returns the callback [Uri] to the caller — the redirect is never actually
/// loaded, so no local server is involved at all.
class OAuthWebViewPage extends StatefulWidget {
  const OAuthWebViewPage({
    super.key,
    required this.authUri,
    required this.callbackPath,
  });

  /// The authorization URL to open (with PKCE parameters).
  final Uri authUri;

  /// Expected path of the loopback callback (e.g. `/oauth/callback`).
  final String callbackPath;

  /// Pushes the page on the global navigator. Resolves with the intercepted
  /// callback URI, or `null` when the user cancelled or no navigator is
  /// available.
  static Future<Uri?> launch(Uri authUri, {required String callbackPath}) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return Future<Uri?>.value();
    return nav.push<Uri?>(
      MaterialPageRoute<Uri?>(
        builder: (_) =>
            OAuthWebViewPage(authUri: authUri, callbackPath: callbackPath),
      ),
    );
  }

  /// True when [uri] targets the registered loopback OAuth callback.
  static bool isLoopbackCallback(Uri uri, String callbackPath) {
    final isLoopback = uri.host == '127.0.0.1' || uri.host == 'localhost';
    return isLoopback && uri.path == callbackPath;
  }

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  var _progress = 0;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                OAuthWebViewPage.isLoopbackCallback(
                  uri,
                  widget.callbackPath,
                )) {
              _complete(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.authUri);
  }

  void _complete(Uri? result) {
    if (_completed) return;
    _completed = true;
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _complete(null),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
