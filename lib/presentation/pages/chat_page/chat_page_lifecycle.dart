part of '../chat_page.dart';

extension _ChatPageLifecycle on _ChatPageState {
  void _handleSettingsChanged() {
    _applyForegroundPolicy(reason: 'settings-changed');
  }

  void _applyForegroundPolicy({required String reason}) {
    final provider = _chatProvider;
    if (provider == null) {
      return;
    }

    void scheduleAndroidProbe(Duration delay) {
      if (!_isMobileRuntime) {
        return;
      }
      unawaited(
        AndroidBackgroundAlertWorker.scheduleProbe(initialDelay: delay),
      );
    }

    void primeAndroidBackgroundSnapshot() {
      if (!_isMobileRuntime) {
        return;
      }

      final serverId = provider.activeServerId.trim();
      if (serverId.isEmpty) {
        return;
      }

      final statusById = <String, String>{};
      for (final entry in provider.sessionStatusById.entries) {
        final sessionId = entry.key.trim();
        if (sessionId.isEmpty) {
          continue;
        }
        statusById[sessionId] = entry.value.type.name;
      }

      final hasActiveSession = statusById.values.any((status) {
        return status == 'busy' || status == 'retry';
      });
      if (!hasActiveSession) {
        return;
      }

      final sessionUpdatedAtById = <String, int>{};
      final sessionTitleById = <String, String>{};
      for (final session in provider.sessions) {
        final sessionId = session.id.trim();
        if (sessionId.isEmpty) {
          continue;
        }

        final title = session.title?.trim();
        if (title != null && title.isNotEmpty) {
          sessionTitleById[sessionId] = title;
        }

        final updatedAt = session.time.millisecondsSinceEpoch;
        if (updatedAt > 0) {
          sessionUpdatedAtById[sessionId] = updatedAt;
        }
      }

      unawaited(
        AndroidBackgroundAlertWorker.primeSnapshot(
          serverId: serverId,
          sessionStatusById: statusById,
          sessionUpdatedAtById: sessionUpdatedAtById,
          sessionTitleById: sessionTitleById,
        ),
      );
    }

    _backgroundRealtimeHoldTimer?.cancel();
    _backgroundRealtimeHoldTimer = null;

    if (_isAppInForeground) {
      AppLogger.debug('foreground_policy reason=$reason mode=active');
      unawaited(provider.setForegroundActive(true));
      return;
    }

    primeAndroidBackgroundSnapshot();

    final settingsProvider = _settingsProvider;
    final keepDesktopRealtime =
        _isDesktopRuntime &&
        (settingsProvider?.desktopCloseBehavior != DesktopCloseBehavior.close);
    if (keepDesktopRealtime) {
      AppLogger.debug('foreground_policy reason=$reason mode=desktop-tray');
      unawaited(provider.setForegroundActive(true));
      return;
    }

    final keepMobileRealtimeTemporarily =
        _isMobileRuntime &&
        (settingsProvider?.keepMobileRealtimeForShortPeriod ?? true) &&
        provider.isCurrentSessionActivelyResponding;
    if (keepMobileRealtimeTemporarily) {
      AppLogger.debug('foreground_policy reason=$reason mode=mobile-hold');
      unawaited(provider.setForegroundActive(true));
      scheduleAndroidProbe(
        AndroidBackgroundAlertWorker.activeSessionProbeInterval,
      );
      _backgroundRealtimeHoldTimer = Timer(
        _ChatPageState._mobileBackgroundRealtimeHoldDuration,
        () {
          if (!mounted || _isAppInForeground) {
            return;
          }
          AppLogger.debug('foreground_policy mode=mobile-hold-expired');
          unawaited(provider.setForegroundActive(false));
        },
      );
      return;
    }

    AppLogger.debug('foreground_policy reason=$reason mode=paused');
    unawaited(provider.setForegroundActive(false));
    scheduleAndroidProbe(const Duration(minutes: 1));
  }

  Future<void> _handleServerScopeChange() async {
    if (!mounted) {
      return;
    }
    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.onServerScopeChanged();
    await _chatProvider?.onServerScopeChanged();
  }

  void _syncChatRouteActivity(ChatProvider chatProvider) {
    final isCurrent = _isChatScreenActive();
    if (_wasChatRouteCurrent == isCurrent) {
      return;
    }
    _wasChatRouteCurrent = isCurrent;
    chatProvider.setChatRouteActive(isCurrent);
    if (isCurrent) {
      _handleReturnToChat(chatProvider, reason: 'route-return');
    }
  }

  void _handleReturnToChat(
    ChatProvider chatProvider, {
    required String reason,
  }) {
    if (!_autoFollowToLatest || chatProvider.currentSession == null) {
      return;
    }
    if (chatProvider.messages.isEmpty ||
        chatProvider.state == ChatState.loading) {
      return;
    }
    AppLogger.debug(
      'Auto-following latest messages after $reason for session=${chatProvider.currentSession!.id}',
    );
    if (chatProvider.isCurrentSessionActivelyResponding) {
      _scrollToBottom(force: true);
      return;
    }
    _revealLatestMessageStartAfterReturn(chatProvider, reason: reason);
  }
}
