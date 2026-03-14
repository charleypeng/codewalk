import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../domain/entities/experience_settings.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/sherpa_model_manager.dart';
import '../../../widgets/searchable_dropdown_form_field.dart';

class _SherpaModelEntry {
  const _SherpaModelEntry({
    required this.code,
    required this.label,
    required this.sizeMb,
  });

  final String code;
  final String label;
  final int sizeMb;
}

class SpeechSettingsSection extends StatefulWidget {
  const SpeechSettingsSection({super.key});

  @override
  State<SpeechSettingsSection> createState() => _SpeechSettingsSectionState();
}

class _SpeechSettingsSectionState extends State<SpeechSettingsSection> {
  final SherpaModelManager _modelManager = di.sl<SherpaModelManager>();

  List<_SherpaModelEntry> _models = const <_SherpaModelEntry>[];
  Map<String, bool> _installedByCode = const <String, bool>{};
  bool _loadingModels = false;
  bool _isMutatingModel = false;
  double _downloadProgress = 0;
  String? _modelError;
  double? _silenceDraftSeconds;

  bool get _isLinux {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  bool get _supportsSherpa {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  bool get _isWindows {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    if (_isLinux) {
      unawaited(_loadModelCatalog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final selectedEngine = settingsProvider.speechToTextEngine;
        final silenceValue =
            _silenceDraftSeconds ??
            settingsProvider.speechSilenceTimeoutSeconds.toDouble();
        return ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            Text(
              'Speech to text',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the recognition engine, silence timeout, and model options.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildEngineCard(settingsProvider),
            const SizedBox(height: 12),
            _buildSilenceCard(
              settingsProvider: settingsProvider,
              silenceValue: silenceValue,
            ),
            if (_isLinux && selectedEngine == SpeechToTextEngine.sherpa) ...[
              const SizedBox(height: 12),
              _buildLinuxModelCard(settingsProvider),
            ],
            if (_isLinux && selectedEngine != SpeechToTextEngine.sherpa) ...[
              const SizedBox(height: 12),
              _buildSherpaModelHintCard(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEngineCard(SettingsProvider settingsProvider) {
    final selectedEngine = settingsProvider.speechToTextEngine;
    final sherpaEnabled = _supportsSherpa;
    final nativeEnabled = !_isLinux;
    final sherpaUnavailableHint =
        defaultTargetPlatform == TargetPlatform.android
        ? 'Unavailable on Android builds optimized for small APK size.'
        : 'Not available on this platform.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engine', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Native starts faster. Sherpa runs fully on-device with heavier setup and deeper model control.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            RadioListTile<SpeechToTextEngine>(
              contentPadding: EdgeInsets.zero,
              value: SpeechToTextEngine.native,
              groupValue: selectedEngine,
              onChanged: nativeEnabled
                  ? (value) {
                      if (value == null) return;
                      unawaited(settingsProvider.setSpeechToTextEngine(value));
                    }
                  : null,
              title: const Text('Native'),
              subtitle: Text(
                nativeEnabled
                    ? 'Simpler and faster startup.'
                    : 'Unavailable on Linux. Use Sherpa for speech input.',
              ),
            ),
            if (!nativeEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.info,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Native STT is disabled on Linux in this app. Sherpa is the default engine.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isWindows)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.info,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Native STT works on Windows when OS speech services are enabled. If native initialization fails, CodeWalk automatically falls back to Sherpa. Check Windows microphone privacy, Online speech recognition, and installed speech language packs.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            RadioListTile<SpeechToTextEngine>(
              contentPadding: EdgeInsets.zero,
              value: SpeechToTextEngine.sherpa,
              groupValue: selectedEngine,
              onChanged: sherpaEnabled
                  ? (value) {
                      if (value == null) return;
                      unawaited(settingsProvider.setSpeechToTextEngine(value));
                    }
                  : null,
              title: const Text('Sherpa'),
              subtitle: Text(
                sherpaEnabled
                    ? 'Heavier, experimental, and bug-prone. Often more precise with downloaded models.'
                    : sherpaUnavailableHint,
              ),
            ),
            if (sherpaEnabled) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.warning_amber_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sherpa is experimental and can fail on some devices. Prefer Native if you want the most stable behavior.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSherpaModelHintCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Symbols.info, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select Sherpa above to manage language packs and download models.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilenceCard({
    required SettingsProvider settingsProvider,
    required double silenceValue,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-stop silence timeout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Listening stops automatically after this many seconds of silence.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Slider.adaptive(
              min: 2,
              max: 10,
              divisions: 8,
              label: '${silenceValue.round()}s',
              value: silenceValue,
              onChanged: (value) {
                setState(() {
                  _silenceDraftSeconds = value;
                });
              },
              onChangeEnd: (value) {
                final seconds = value.round();
                setState(() {
                  _silenceDraftSeconds = null;
                });
                unawaited(
                  settingsProvider.setSpeechSilenceTimeoutSeconds(seconds),
                );
              },
            ),
            Text(
              '${silenceValue.round()} seconds',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinuxModelCard(SettingsProvider settingsProvider) {
    final selectedCode = _normalizeLanguageSelection(
      settingsProvider.sherpaLanguageCode,
    );
    final effectiveCode = _effectiveLanguageCode(selectedCode);
    _SherpaModelEntry? selectedModel;
    for (final model in _models) {
      if (model.code == effectiveCode) {
        selectedModel = model;
        break;
      }
    }
    final installed = _installedByCode[effectiveCode] ?? false;
    final installedLabels = _models
        .where((model) => _installedByCode[model.code] == true)
        .map((model) => model.label)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sherpa models (Linux)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pick language packs and download/remove models for on-device recognition.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_loadingModels)
              const Center(child: CircularProgressIndicator())
            else ...[
              SearchableDropdownFormField<String>(
                value: selectedCode,
                decoration: const InputDecoration(
                  labelText: 'Sherpa language',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                searchHintText: 'Search Sherpa language',
                emptyText: 'No language packs found',
                searchTermsBuilder: (value) {
                  if (value == kSherpaLanguageSystem) {
                    return <String>[
                      'system default',
                      _modelManager.detectSystemLanguage(),
                    ];
                  }
                  for (final model in _models) {
                    if (model.code == value) {
                      return <String>[model.code, model.label];
                    }
                  }
                  return <String>[value];
                },
                items: [
                  DropdownMenuItem<String>(
                    value: kSherpaLanguageSystem,
                    child: Text(
                      'System default (${_modelManager.detectSystemLanguage().toUpperCase()})',
                    ),
                  ),
                  ..._models.map(
                    (model) => DropdownMenuItem<String>(
                      value: model.code,
                      child: Text(model.label),
                    ),
                  ),
                ],
                onChanged: _isMutatingModel
                    ? null
                    : (value) {
                        if (value == null) return;
                        final nextCode = _effectiveLanguageCode(value);
                        _modelManager.setPreferredLanguage(nextCode);
                        unawaited(
                          settingsProvider.setSherpaLanguageCode(value),
                        );
                        setState(() {
                          _modelError = null;
                        });
                      },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Chip(
                    avatar: Icon(
                      installed ? Symbols.check_circle_outline : Symbols.info,
                      size: 18,
                    ),
                    label: Text(
                      installed
                          ? 'Model installed (${effectiveCode.toUpperCase()})'
                          : 'Model missing (${effectiveCode.toUpperCase()})',
                    ),
                  ),
                  const Spacer(),
                  if (selectedModel != null)
                    Text(
                      '~${selectedModel.sizeMb} MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _isMutatingModel || installed
                        ? null
                        : () => unawaited(_downloadModel(effectiveCode)),
                    icon: const Icon(Symbols.download_rounded),
                    label: const Text('Download'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isMutatingModel || !installed
                        ? null
                        : () => unawaited(_deleteModel(effectiveCode)),
                    icon: const Icon(Symbols.delete_outline),
                    label: const Text('Remove'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh status',
                    onPressed: _isMutatingModel
                        ? null
                        : () => unawaited(_refreshModelStatuses()),
                    icon: const Icon(Symbols.refresh_rounded),
                  ),
                ],
              ),
              if (_isMutatingModel) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                ),
              ],
              if (_modelError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _modelError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (installedLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Installed languages',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: installedLabels
                      .map((label) => Chip(label: Text(label)))
                      .toList(growable: false),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadModelCatalog() async {
    setState(() {
      _loadingModels = true;
      _modelError = null;
    });
    try {
      final raw = await rootBundle.loadString('assets/sherpa_models.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entries = (json['models'] as List)
          .map((entry) {
            final map = entry as Map<String, dynamic>;
            return _SherpaModelEntry(
              code: map['code'] as String,
              label: map['label'] as String,
              sizeMb: (map['size_mb'] as num).toInt(),
            );
          })
          .toList(growable: false);
      _models = entries;
      await _refreshModelStatuses();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _modelError = 'Failed to load Sherpa model catalog: $error';
        _loadingModels = false;
      });
    }
  }

  Future<void> _refreshModelStatuses() async {
    if (_models.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _installedByCode = const <String, bool>{};
        _loadingModels = false;
      });
      return;
    }
    final statuses = <String, bool>{};
    for (final model in _models) {
      statuses[model.code] = await _modelManager.hasModel(model.code);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _installedByCode = statuses;
      _loadingModels = false;
    });
  }

  Future<void> _downloadModel(String code) async {
    setState(() {
      _isMutatingModel = true;
      _downloadProgress = 0;
      _modelError = null;
    });
    try {
      await _modelManager.downloadModel(
        code,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      _modelManager.setPreferredLanguage(code);
      if (!mounted) {
        return;
      }
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.setSherpaLanguageCode(code);
      await _refreshModelStatuses();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _modelError = 'Download failed: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isMutatingModel = false;
        _downloadProgress = 0;
      });
    }
  }

  Future<void> _deleteModel(String code) async {
    setState(() {
      _isMutatingModel = true;
      _modelError = null;
    });
    try {
      await _modelManager.deleteModel(code);
      await _refreshModelStatuses();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _modelError = 'Failed to remove model: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isMutatingModel = false;
      });
    }
  }

  String _normalizeLanguageSelection(String raw) {
    if (raw == kSherpaLanguageSystem) {
      return kSherpaLanguageSystem;
    }
    final matchesKnownModel = _models.any((model) => model.code == raw);
    if (matchesKnownModel) {
      return raw;
    }
    return kSherpaLanguageSystem;
  }

  String _effectiveLanguageCode(String selectedCode) {
    if (selectedCode == kSherpaLanguageSystem) {
      return _modelManager.detectSystemLanguage();
    }
    return selectedCode;
  }
}
