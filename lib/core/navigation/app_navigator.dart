import 'package:flutter/widgets.dart';

/// Global navigator key so non-UI layers (e.g. the OAuth flow triggered from
/// providers) can present full-screen UI such as the OAuth WebView page.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
