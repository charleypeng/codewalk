part of '../chat_page.dart';

extension _ChatPageLifecycle on _ChatPageState {
  String _foregroundPolicySettingsSignature(ExperienceSettings settings) {
    return '${shouldRunAndroidBackgroundAlerts(settings)}|'
        '${settings.desktopCloseBehavior.name}|'
        '${settings.keepMobileRealtimeForShortPeriod}';
  }

  void _handleSettingsChanged() {
    final settings =
        _settingsProvider?.settings ?? ExperienceSettings.defaults();
    final nextForegroundPolicySignature = _foregroundPolicySettingsSignature(
      settings,
    );
    if (_lastForegroundPolicySettingsSignature !=
        nextForegroundPolicySignature) {
      _applyForegroundPolicy(reason: 'settings-changed');
      _lastForegroundPolicySettingsSignature = nextForegroundPolicySignature;
    }
    _autoApprovePermissionCooldownIds.clear();
    _clearReturnRevealBaseline();
    _pendingFinalAssistantRevealMessageId = null;
    _finalAssistantRevealScheduled = false;
    _pendingFinalAssistantRevealAttempts = 0;
    final chatProvider = _chatProvider;
    if (chatProvider != null &&
        !chatProvider.isCurrentSessionActivelyResponding) {
      _suppressPostCompletionAutoSnap = false;
      _shouldRevealFinalAssistantOnCompletion = false;
    }
    _scheduleAutoApprovePermissionDrain(reason: 'settings-changed');
  }

  void _handleChatProviderChanged() {
    _scheduleAutoApprovePermissionDrain(reason: 'chat-provider-changed');
  }

  void _scheduleAutoApprovePermissionDrain({required String reason}) {
    final chatProvider = _chatProvider;
    final settingsProvider = _settingsProvider;
    if (!mounted || chatProvider == null || settingsProvider == null) {
      return;
    }

    final visibleRequestIds = chatProvider.currentThreadPermissionRequests
        .map((request) => request.id)
        .toSet();
    _autoApprovePermissionCooldownIds.removeWhere(
      (requestId) => !visibleRequestIds.contains(requestId),
    );
    if (visibleRequestIds.isEmpty) {
      return;
    }
    if (!settingsProvider.initialized) {
      return;
    }
    if (!settingsProvider.composerAutoApprovePermissions) {
      return;
    }
    if (_autoApprovePermissionDrainScheduled) {
      return;
    }
    _autoApprovePermissionDrainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoApprovePermissionDrainScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_drainAutoApprovePermissions(reason: reason));
    });
  }

  Future<void> _drainAutoApprovePermissions({required String reason}) async {
    if (_autoApprovePermissionDrainRunning) {
      _autoApprovePermissionDrainQueued = true;
      return;
    }

    _autoApprovePermissionDrainRunning = true;
    try {
      do {
        _autoApprovePermissionDrainQueued = false;
        final chatProvider = _chatProvider;
        final settingsProvider = _settingsProvider;
        if (!mounted || chatProvider == null || settingsProvider == null) {
          return;
        }
        if (!settingsProvider.initialized) {
          return;
        }
        if (!settingsProvider.composerAutoApprovePermissions) {
          return;
        }

        while (mounted) {
          if (chatProvider.isRespondingInteraction) {
            break;
          }

          final nextRequest = chatProvider.currentThreadPermissionRequests
              .where(
                (request) =>
                    !_autoApprovePermissionCooldownIds.contains(request.id),
              )
              .firstOrNull;
          if (nextRequest == null) {
            break;
          }

          AppLogger.info(
            'Auto-approving permission request=${nextRequest.id} session=${nextRequest.sessionId} reason=$reason',
          );
          try {
            await chatProvider.respondPermissionRequest(
              requestId: nextRequest.id,
              reply: 'once',
            );
          } catch (error, stackTrace) {
            AppLogger.error(
              'Failed to auto-approve permission request=${nextRequest.id}',
              error: error,
              stackTrace: stackTrace,
            );
            _autoApprovePermissionCooldownIds.add(nextRequest.id);
            break;
          }
          if (!mounted) {
            return;
          }

          final stillPending = chatProvider.currentThreadPermissionRequests.any(
            (request) => request.id == nextRequest.id,
          );
          if (stillPending) {
            _autoApprovePermissionCooldownIds.add(nextRequest.id);
            break;
          }
          _autoApprovePermissionCooldownIds.remove(nextRequest.id);
        }
      } while (_autoApprovePermissionDrainQueued);
    } finally {
      _autoApprovePermissionDrainRunning = false;
    }
  }

  void _applyForegroundPolicy({required String reason}) {
    final provider = _chatProvider;
    if (provider == null) {
      return;
    }

    final settingsProvider = _settingsProvider;

    void scheduleAndroidProbe(Duration delay) {
      if (!_isMobileRuntime) {
        return;
      }
      unawaited(
        AndroidBackgroundAlertWorker.scheduleProbe(initialDelay: delay),
      );
    }

    void syncAndroidForegroundMonitor({
      required bool enabled,
      required int activeSessionCount,
    }) {
      if (!_isMobileRuntime) {
        return;
      }
      unawaited(
        AndroidForegroundMonitorService.sync(
          enabled: enabled,
          activeSessionCount: activeSessionCount,
        ),
      );
    }

    final statusById = <String, String>{};
    for (final entry in provider.sessionStatusById.entries) {
      final sessionId = entry.key.trim();
      if (sessionId.isEmpty) {
        continue;
      }
      statusById[sessionId] = entry.value.type.name;
    }
    final activeSessionCount = countActiveBackgroundSessions(statusById);
    final hasActiveSession = activeSessionCount > 0;
    final backgroundAlertsEnabled =
        _isMobileRuntime &&
        shouldRunAndroidBackgroundAlerts(
          settingsProvider?.settings ?? ExperienceSettings.defaults(),
        );

    void primeAndroidBackgroundSnapshot() {
      if (!_isMobileRuntime) {
        return;
      }

      final serverId = provider.activeServerId.trim();
      if (serverId.isEmpty) {
        return;
      }
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
      syncAndroidForegroundMonitor(enabled: false, activeSessionCount: 0);
      unawaited(provider.setForegroundActive(true));
      return;
    }

    if (!backgroundAlertsEnabled) {
      AppLogger.debug(
        'foreground_policy reason=$reason mode=background-disabled',
      );
      syncAndroidForegroundMonitor(enabled: false, activeSessionCount: 0);
      unawaited(provider.setForegroundActive(false));
      return;
    }

    primeAndroidBackgroundSnapshot();

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
      syncAndroidForegroundMonitor(
        enabled: hasActiveSession,
        activeSessionCount: activeSessionCount,
      );
      unawaited(provider.setForegroundActive(true));
      if (hasActiveSession) {
        scheduleAndroidProbe(
          AndroidBackgroundAlertWorker.activeSessionProbeInterval,
        );
      }
      _backgroundRealtimeHoldTimer = Timer(
        _ChatPageState._mobileBackgroundRealtimeHoldDuration,
        () {
          if (!mounted || _isAppInForeground) {
            return;
          }
          AppLogger.debug('foreground_policy mode=mobile-hold-expired');
          syncAndroidForegroundMonitor(enabled: false, activeSessionCount: 0);
          unawaited(provider.setForegroundActive(false));
        },
      );
      return;
    }

    AppLogger.debug('foreground_policy reason=$reason mode=paused');
    syncAndroidForegroundMonitor(enabled: false, activeSessionCount: 0);
    unawaited(provider.setForegroundActive(false));
    if (hasActiveSession) {
      scheduleAndroidProbe(
        AndroidBackgroundAlertWorker.activeSessionProbeInterval,
      );
    }
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
    if (!isCurrent) {
      _captureReturnRevealBaseline(chatProvider);
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
      _captureReturnRevealBaseline(chatProvider);
      _scrollToBottom(force: true);
      return;
    }
    if (!_shouldRevealLatestMessageAfterReturn(chatProvider)) {
      _captureReturnRevealBaseline(chatProvider);
      return;
    }
    _captureReturnRevealBaseline(chatProvider);
    _revealLatestMessageStartAfterReturn(chatProvider, reason: reason);
  }
}
