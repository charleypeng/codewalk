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
    this.autoDiscover = false,
  });

  final Project project;
  final double size;
  final Color? color;
  final bool autoDiscover;

  @override
  State<ProjectIcon> createState() => _ProjectIconState();
}

class _ProjectIconState extends State<ProjectIcon> {
  ProjectIconProvider? _provider;
  ProjectIconProvider? _lastLoadProvider;
  String? _lastLoadKey;
  bool? _lastLoadAutoDiscover;

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
        oldWidget.project.path != widget.project.path ||
        oldWidget.autoDiscover != widget.autoDiscover) {
      _loadStoredIcon();
    }
  }

  void _loadStoredIcon() {
    final provider = _provider;
    if (provider == null) {
      return;
    }
    final key = projectIconKeyFor(widget.project);
    if (identical(_lastLoadProvider, provider) &&
        _lastLoadKey == key &&
        _lastLoadAutoDiscover == widget.autoDiscover) {
      return;
    }
    _lastLoadProvider = provider;
    _lastLoadKey = key;
    _lastLoadAutoDiscover = widget.autoDiscover;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.autoDiscover) {
        provider.autoDiscoverIcon(widget.project);
      } else {
        provider.loadStoredIcon(widget.project);
      }
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
