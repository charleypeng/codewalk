part of '../chat_input_widget.dart';

extension _ChatInputSpeechController on _ChatInputWidgetState {
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
    final fallbackEngine = primaryEngine == SpeechToTextEngine.native
        ? SpeechToTextEngine.sherpa
        : SpeechToTextEngine.native;

    final primaryService = _serviceForEngine(primaryEngine);
    if (primaryService != null && await primaryService.initialize()) {
      return _SpeechServiceResolution(
        service: primaryService,
        engine: primaryEngine,
        usedFallback: false,
      );
    }

    final fallbackService = _serviceForEngine(fallbackEngine);
    if (fallbackService != null && await fallbackService.initialize()) {
      return _SpeechServiceResolution(
        service: fallbackService,
        engine: fallbackEngine,
        usedFallback: true,
        unavailableReason: primaryService?.unavailableReason,
      );
    }

    return null;
  }

  Future<void> _startListening() async {
    if (!widget.enabled || _isSending || _isStartingListening) return;

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

    _speechPrefix = _controller.text;
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
    final nextText = _appendSpeechSegment(_speechPrefix, spokenText);

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );

    _setState(() {
      _isComposing = nextText.trim().isNotEmpty;
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;

    // 'model_required' is emitted by Sherpa when no model is installed for the
    // selected language. Show the download/setup dialog.
    if (status == 'model_required') {
      _finishListeningLoading();
      _showSherpaDownloadDialog();
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
}
