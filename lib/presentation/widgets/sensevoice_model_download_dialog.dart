import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/injection_container.dart' as di;
import '../../domain/entities/experience_settings.dart';
import '../services/sensevoice_model_manager.dart';
import 'modal_primary_action_shortcuts.dart';

class _SenseVoiceModelEntry {
  const _SenseVoiceModelEntry({
    required this.id,
    required this.label,
    required this.sizeMb,
  });

  final String id;
  final String label;
  final int sizeMb;
}

class SenseVoiceModelDownloadDialog extends StatefulWidget {
  const SenseVoiceModelDownloadDialog({super.key});

  @override
  State<SenseVoiceModelDownloadDialog> createState() =>
      _SenseVoiceModelDownloadDialogState();
}

class _SenseVoiceModelDownloadDialogState
    extends State<SenseVoiceModelDownloadDialog> {
  final _manager = di.sl<SenseVoiceModelManager>();

  List<_SenseVoiceModelEntry> _models = <_SenseVoiceModelEntry>[];
  String? _selectedId;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/sensevoice_models.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entries = (json['models'] as List)
          .map((entry) {
            final map = entry as Map<String, dynamic>;
            return _SenseVoiceModelEntry(
              id: map['id'] as String,
              label: map['label'] as String,
              sizeMb: (map['size_mb'] as num).toInt(),
            );
          })
          .toList(growable: false);
      final preselect =
          entries.any((entry) => entry.id == kSenseVoiceModelDefault)
          ? kSenseVoiceModelDefault
          : entries.first.id;
      _manager.setPreferredModelId(preselect);
      setState(() {
        _models = entries;
        _selectedId = preselect;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load SenseVoice model list: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _startDownload() async {
    final id = _selectedId;
    if (id == null) {
      return;
    }
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMessage = null;
    });
    try {
      _manager.setPreferredModelId(id);
      await _manager.downloadModel(
        id,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedId == null
        ? null
        : _models.firstWhere(
            (entry) => entry.id == _selectedId,
            orElse: () => _models.first,
          );
    return ModalPrimaryActionShortcuts(
      autofocus: true,
      enabled: !_isDownloading && _selectedId != null,
      onPrimaryAction: () {
        unawaited(_startDownload());
      },
      child: AlertDialog(
        title: const Text('SenseVoice Setup'),
        content: SizedBox(
          width: 380,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(selected),
        ),
        actions: _isDownloading
            ? null
            : <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _selectedId == null ? null : _startDownload,
                  child: const Text('Download'),
                ),
              ],
      ),
    );
  }

  Widget _buildContent(_SenseVoiceModelEntry? selected) {
    if (_errorMessage != null && !_isDownloading) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'SenseVoice runs on-device through sherpa_onnx offline recognition. '
          'It is strongest for Chinese, Cantonese, Japanese, Korean, and English.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'SenseVoice model',
            border: OutlineInputBorder(),
          ),
          items: _models
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.id,
                  child: Text(entry.label),
                ),
              )
              .toList(growable: false),
          onChanged: _isDownloading
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  _manager.setPreferredModelId(value);
                  setState(() {
                    _selectedId = value;
                  });
                },
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '~${selected.sizeMb} MB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_isDownloading) ...<Widget>[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 4),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
