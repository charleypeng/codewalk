part of '../chat_input_widget.dart';

extension _ChatInputSpeechController on _ChatInputWidgetState {
  void _focusInputFromExternal() {
    _ensureInputFocus();
  }

  Future<void> _toggleVoiceInputFromExternal() async {
    _ensureInputFocus();
    await _toggleVoiceInput();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isStartingListening) {
      return;
    }
    if (_isListening) {
      await _stopListening();
      return;
    }
    await _startListening();
  }

  Future<_SpeechServiceResolution?> _resolveSpeechServiceForStart(
    SettingsProvider settingsProvider,
  ) async {
    final primaryEngine = settingsProvider.speechToTextEngine;
    final candidates = <SpeechToTextEngine>[primaryEngine];
    if (primaryEngine == SpeechToTextEngine.native) {
      candidates.add(SpeechToTextEngine.sherpa);
    } else if (primaryEngine == SpeechToTextEngine.sherpa) {
      candidates.add(SpeechToTextEngine.native);
    } else {
      if (_isNativeEngineSupported) {
        candidates.add(SpeechToTextEngine.native);
      }
      if (_isSherpaEngineSupported) {
        candidates.add(SpeechToTextEngine.sherpa);
      }
    }

    String? unavailableReason;
    for (var i = 0; i < candidates.length; i++) {
      final engine = candidates[i];
      final service = _serviceForEngine(engine);
      if (service == null) {
        continue;
      }
      if (await service.initialize()) {
        return _SpeechServiceResolution(
          service: service,
          engine: engine,
          usedFallback: i > 0,
          unavailableReason: unavailableReason,
        );
      }
      unavailableReason ??= service.unavailableReason;
    }

    return null;
  }

  Future<void> _startListening() async {
    if (!widget.enabled || _isStartingListening) return;

    if (!mounted) {
      return;
    }

    _startListeningLoading();
    // Let Flutter paint the loading state before potentially heavy STT init.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final resolution = await _resolveSpeechServiceForStart(settingsProvider);
    if (resolution == null) {
      _finishListeningLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is unavailable on this device'),
        ),
      );
      return;
    }

    _activeSpeechService = resolution.service;
    if (resolution.usedFallback && mounted) {
      final label = _speechEngineLabel(resolution.engine);
      final reason = resolution.unavailableReason?.trim();
      final reasonSuffix = reason != null && reason.isNotEmpty
          ? ' ($reason)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected STT engine unavailable$reasonSuffix. Using $label.',
          ),
        ),
      );
    }

    final pauseFor = Duration(
      seconds: settingsProvider.speechSilenceTimeoutSeconds,
    );

    final textWindow = splitComposerTextAtSelection(_controller.value);
    _speechPrefix = textWindow.leadingText;
    _speechSuffix = textWindow.trailingText;
    _speechCommittedText = '';
    try {
      await _speechService.startListening(
        onResult: _onSpeechResult,
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        pauseFor: pauseFor,
        localeId: _localeForService(_speechService, settingsProvider),
      );
      if (!mounted) return;
      _setState(() {
        _isListening = _speechService.isListening;
      });
      if (_isListening) {
        _finishListeningLoading();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Voice input start failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _setState(() {
        _isListening = false;
      });
      _finishListeningLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start voice input')),
      );
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechService.stopListening();
    } catch (_) {
      // Ignore platform stop errors to keep compose flow resilient.
    } finally {
      _finishListeningLoading();
      if (mounted) {
        _setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _onSpeechResult(String recognized, bool isFinal) {
    if (!mounted) return;

    final text = recognized.trim();
    if (isFinal && text.isNotEmpty) {
      _speechCommittedText = _appendSpeechSegment(_speechCommittedText, text);
    }

    final spokenText = isFinal
        ? _speechCommittedText
        : _appendSpeechSegment(_speechCommittedText, text);
    final leadingText = _appendSpeechSegment(_speechPrefix, spokenText);
    final nextValue = composeComposerValueWithSuffix(
      leadingText: leadingText,
      trailingText: _speechSuffix,
    );
    _controller.value = nextValue;

    _setState(() {
      _isComposing = nextValue.text.trim().isNotEmpty;
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;

    // 'model_required' is emitted by downloadable on-device engines when no
    // local model is installed yet. Show the matching setup dialog.
    if (status == 'model_required') {
      _finishListeningLoading();
      if (_speechService is MoonshineSpeechInputService) {
        _showMoonshineDownloadDialog();
      } else {
        _showSherpaDownloadDialog();
      }
      return;
    }

    if (status == 'listening' || status == 'done') {
      _finishListeningLoading();
    }

    final listening = status == 'listening' || _speechService.isListening;
    if (_isListening == listening) return;
    _setState(() {
      _isListening = listening;
    });
  }

  void _onSpeechError() {
    if (!mounted) return;
    _finishListeningLoading();
    _setState(() {
      _isListening = false;
    });
  }

  Future<void> _showSherpaDownloadDialog() async {
    if (!mounted) return;
    _finishListeningLoading();
    _setState(() {
      _isListening = false;
    });
    final downloaded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SherpaModelDownloadDialog(),
    );
    // Re-initialize the service (model is now on disk) and start listening.
    if (downloaded == true && mounted) {
      _sherpaSpeechServiceInstance = null;
      _activeSpeechService = null;
      await _startListening();
    }
  }

  Future<void> _showMoonshineDownloadDialog() async {
    if (!mounted) return;
    _finishListeningLoading();
    _setState(() {
      _isListening = false;
    });
    final downloaded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MoonshineModelDownloadDialog(),
    );
    if (downloaded == true && mounted) {
      _moonshineSpeechServiceInstance = null;
      _activeSpeechService = null;
      await _startListening();
    }
  }
}
