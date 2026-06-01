import '../../../core/i18n/l10n_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../services/file_part_action_service_shared.dart';
import '../../theme/app_animations.dart';
import '../../providers/quota_provider.dart';
import 'quota_provider_group_row.dart';

class QuotaPopupSection extends StatefulWidget {
  const QuotaPopupSection({super.key, required this.serverId});

  final String? serverId;

  @override
  State<QuotaPopupSection> createState() => _QuotaPopupSectionState();
}

class _QuotaPopupSectionState extends State<QuotaPopupSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<QuotaProvider>().ensureLoaded(serverId: widget.serverId);
    });
  }

  @override
  void didUpdateWidget(covariant QuotaPopupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.read<QuotaProvider>().ensureLoaded(
          serverId: widget.serverId,
          force: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, quotaProvider, _) {
        final groups = quotaProvider.groups;
        final showOpenCodeGoSetup = quotaProvider.openCodeGoSetupRequired;
        final isInitialLoading =
            quotaProvider.isLoading && quotaProvider.lastFetchedAt == null;
        if (groups.isEmpty && !isInitialLoading && !showOpenCodeGoSetup) {
          AppLogger.info(
            '[QuotaUI] popup section hidden '
            '(loading=${quotaProvider.isLoading}, serverId=${widget.serverId})',
          );
          return const SizedBox.shrink();
        }
        AppLogger.info(
          '[QuotaUI] popup section render groups='
          '${groups.map((group) => '${group.providerId}:${group.entries.length}').toList()}',
        );
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rate limits',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppAnimations.standard,
                  switchInCurve: AppAnimations.standardCurve,
                  switchOutCurve: AppAnimations.standardCurve,
                  child: quotaProvider.isLoading
                      ? _QuotaSweepText(
                          key: const ValueKey('quota-refreshing-label'),
                          text: 'Refreshing...',
                          duration: const Duration(milliseconds: 1100),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : TextButton(
                          key: const ValueKey('quota-refresh-button'),
                          onPressed: () {
                            context.read<QuotaProvider>().ensureLoaded(
                              serverId: widget.serverId,
                              force: true,
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            context.l10n.chatRefresh,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (isInitialLoading) ...[
              const SizedBox(height: 8),
              const _QuotaInitialLoadingState(),
            ] else ...[
              for (final group in groups) QuotaProviderGroupRow(group: group),
              if (showOpenCodeGoSetup)
                _OpenCodeGoSetupCard(
                  serverId: widget.serverId,
                  hasSavedCredentials:
                      quotaProvider.hasOpenCodeGoDashboardCredentials,
                  error: quotaProvider.openCodeGoError,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _OpenCodeGoSetupCard extends StatelessWidget {
  const _OpenCodeGoSetupCard({
    required this.serverId,
    required this.hasSavedCredentials,
    required this.error,
  });

  final String? serverId;
  final bool hasSavedCredentials;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = hasSavedCredentials
        ? 'OpenCode Go needs reconnect'
        : 'OpenCode Go detected';
    final description = hasSavedCredentials
        ? 'Refresh the dashboard credentials to restore usage bars.'
        : 'Connect the usage dashboard to show rolling, weekly, and monthly limits.';
    return Container(
      key: const ValueKey('opencode-go-quota-setup-card'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (error != null && error!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonal(
                key: const ValueKey('opencode-go-connect-usage-dashboard'),
                onPressed: () => _showOpenCodeGoDashboardDialog(context),
                child: Text(hasSavedCredentials ? 'Reconnect' : 'Connect'),
              ),
              if (hasSavedCredentials)
                TextButton(
                  key: const ValueKey('opencode-go-forget-credentials'),
                  onPressed: () {
                    context
                        .read<QuotaProvider>()
                        .forgetOpenCodeGoDashboardCredentials(
                          serverId: serverId,
                        );
                  },
                  child: Text(context.l10n.quotaForget),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showOpenCodeGoDashboardDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _OpenCodeGoDashboardDialog(serverId: serverId);
      },
    );
  }
}

class _OpenCodeGoDashboardDialog extends StatefulWidget {
  const _OpenCodeGoDashboardDialog({required this.serverId});

  final String? serverId;

  @override
  State<_OpenCodeGoDashboardDialog> createState() =>
      _OpenCodeGoDashboardDialogState();
}

class _OpenCodeGoDashboardDialogState
    extends State<_OpenCodeGoDashboardDialog> {
  final _workspaceController = TextEditingController();
  final _cookieController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _workspaceController.dispose();
    _cookieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.quotaOpenCodeGoUsage),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('opencode-go-open-dashboard'),
                onPressed: _openDashboard,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(context.l10n.quotaOpenDashboard),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('opencode-go-workspace-field'),
              controller: _workspaceController,
              decoration: InputDecoration(
                labelText: context.l10n.quotaWorkspaceId,
                hintText: context.l10n.quotaWorkspaceId,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('opencode-go-cookie-field'),
              controller: _cookieController,
              decoration: InputDecoration(
                labelText: context.l10n.quotaAuthCookie,
                hintText: context.l10n.quotaAuthCookie,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('opencode-go-save-dashboard-credentials'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? Text(context.l10n.quotaSaving)
              : Text(context.l10n.commonSave),
        ),
      ],
    );
  }

  Future<void> _openDashboard() async {
    await safeLaunch(Uri.parse('https://opencode.ai/auth'));
  }

  Future<void> _save() async {
    final workspaceId = _workspaceController.text.trim();
    final authCookie = _cookieController.text.trim();
    if (workspaceId.isEmpty || authCookie.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    await context.read<QuotaProvider>().saveOpenCodeGoDashboardCredentials(
      serverId: widget.serverId,
      workspaceId: workspaceId,
      authCookie: authCookie,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _QuotaInitialLoadingState extends StatefulWidget {
  const _QuotaInitialLoadingState();

  @override
  State<_QuotaInitialLoadingState> createState() =>
      _QuotaInitialLoadingStateState();
}

class _QuotaInitialLoadingStateState extends State<_QuotaInitialLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _rowSpecs = <(double, double)>[
    (0.56, 0.22),
    (0.74, 0.32),
    (0.62, 0.26),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.enabled(context)) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final animate = AppAnimations.enabled(context);

    return Column(
      key: const ValueKey('quota-initial-loading-state'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (labelWidth, barWidth) in _rowSpecs)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _QuotaLoadingRow(
              labelWidthFactor: labelWidth,
              barWidthFactor: barWidth,
              color: baseColor,
              controller: animate ? _controller : null,
            ),
          ),
      ],
    );
  }
}

class _QuotaLoadingRow extends StatelessWidget {
  const _QuotaLoadingRow({
    required this.labelWidthFactor,
    required this.barWidthFactor,
    required this.color,
    required this.controller,
  });

  final double labelWidthFactor;
  final double barWidthFactor;
  final Color color;
  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    final placeholder = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FractionallySizedBox(
          widthFactor: labelWidthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: barWidthFactor,
            backgroundColor: color.withValues(alpha: 0.45),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );

    if (controller == null) {
      return placeholder;
    }

    return AnimatedBuilder(
      animation: controller!,
      child: placeholder,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final dx = controller!.value * 2 - 0.5;
            return LinearGradient(
              begin: Alignment(dx - 0.3, 0),
              end: Alignment(dx + 0.3, 0),
              colors: [color, color.withValues(alpha: 0.4), color],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _QuotaSweepText extends StatefulWidget {
  const _QuotaSweepText({
    super.key,
    required this.text,
    required this.duration,
    this.style,
  });

  final String text;
  final Duration duration;
  final TextStyle? style;

  @override
  State<_QuotaSweepText> createState() => _QuotaSweepTextState();
}

class _QuotaSweepTextState extends State<_QuotaSweepText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.enabled(context)) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _QuotaSweepText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (AppAnimations.enabled(context)) {
        _controller
          ..stop()
          ..repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(widget.text, style: widget.style);
    if (!AppAnimations.enabled(context)) {
      return textWidget;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = widget.style?.color ?? colorScheme.onSurfaceVariant;
    final dimColor = baseColor.withValues(alpha: 0.72);
    final highlightColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.35),
      baseColor,
    );

    return AnimatedBuilder(
      animation: _controller,
      child: textWidget,
      builder: (context, child) {
        final rawCenter = (_controller.value * 1.8) - 0.4;
        final left = (rawCenter - 0.16).clamp(0.0, 1.0);
        final innerLeft = (rawCenter - 0.06).clamp(0.0, 1.0);
        final center = rawCenter.clamp(0.0, 1.0);
        final innerRight = (rawCenter + 0.06).clamp(0.0, 1.0);
        final right = (rawCenter + 0.16).clamp(0.0, 1.0);

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                dimColor,
                dimColor,
                baseColor,
                highlightColor,
                baseColor,
                dimColor,
                dimColor,
              ],
              stops: [0.0, left, innerLeft, center, innerRight, right, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}
