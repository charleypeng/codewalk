import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/project.dart';
import '../providers/project_icon_provider.dart';
import '../services/project_icon_models.dart';

class ProjectIcon extends StatefulWidget {
  const ProjectIcon({
    super.key,
    required this.project,
    this.size = 20,
    this.color,
  });

  final Project project;
  final double size;
  final Color? color;

  @override
  State<ProjectIcon> createState() => _ProjectIconState();
}

class ProjectIconDiscoveryButton extends StatelessWidget {
  const ProjectIconDiscoveryButton({
    super.key,
    required this.project,
    required this.tooltip,
    this.enabled = true,
    this.color,
    this.onResult,
  });

  final Project project;
  final String tooltip;
  final bool enabled;
  final Color? color;
  final ValueChanged<ProjectIconDiscoveryResult>? onResult;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIconProvider?>();
    if (provider == null || !provider.discoverySupported) {
      return const SizedBox.shrink();
    }
    final discovering = provider.isDiscovering(project);
    return IconButton(
      icon: discovering
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(Symbols.manage_search, size: 20, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      onPressed: enabled && !discovering
          ? () async {
              final result = await provider.discoverIcon(project);
              onResult?.call(result);
            }
          : null,
    );
  }
}

class _ProjectIconState extends State<ProjectIcon> {
  ProjectIconProvider? _provider;
  ProjectIconProvider? _lastLoadProvider;
  String? _lastLoadKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ProjectIconProvider?>();
    if (!identical(_provider, provider)) {
      _provider = provider;
    }
    _loadStoredIcon();
  }

  @override
  void didUpdateWidget(covariant ProjectIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id ||
        oldWidget.project.path != widget.project.path) {
      _loadStoredIcon();
    }
  }

  void _loadStoredIcon() {
    final provider = _provider;
    if (provider == null) {
      return;
    }
    final key = projectIconKeyFor(widget.project);
    if (identical(_lastLoadProvider, provider) && _lastLoadKey == key) {
      return;
    }
    _lastLoadProvider = provider;
    _lastLoadKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      provider.loadStoredIcon(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectIconProvider?>();
    final icon = provider?.iconFor(widget.project);
    if (icon == null) {
      return _fallbackIcon();
    }
    final size = widget.size;
    if (icon.metadata.storedFormat == ProjectIconFormat.svg) {
      return _clipIcon(
        SvgPicture.memory(
          icon.bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _fallbackIcon(),
          errorBuilder: (_, _, _) => _fallbackIcon(),
        ),
      );
    }
    final cacheSize = size.isFinite && size > 0
        ? (size * MediaQuery.devicePixelRatioOf(context)).ceil()
        : null;
    return _clipIcon(
      Image.memory(
        icon.bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallbackIcon(),
      ),
    );
  }

  Widget _clipIcon(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * 0.22),
      child: child,
    );
  }

  Widget _fallbackIcon() {
    return Icon(Symbols.folder_open, size: widget.size, color: widget.color);
  }
}
