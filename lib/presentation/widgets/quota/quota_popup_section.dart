import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
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
        if (groups.isEmpty) {
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
            Text(
              'Rate limits',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final group in groups) QuotaProviderGroupRow(group: group),
          ],
        );
      },
    );
  }
}
