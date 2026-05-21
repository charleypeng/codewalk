part of '../chat_input_widget.dart';

extension _ChatInputSuggestionPopover on _ChatInputWidgetState {
  double _popoverMaxHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final visibleHeight = media.size.height - media.viewInsets.bottom;
    final reservedInputSpace =
        _ChatInputWidgetState._inputRowHeight + 18 + media.viewPadding.bottom;
    final availableForPopover = visibleHeight - reservedInputSpace;
    const maxByInput =
        _ChatInputWidgetState._inputRowHeight *
        _ChatInputWidgetState._popoverInputHeightMultiplier;
    return math.max(0, math.min(maxByInput, availableForPopover));
  }

  Widget _buildSuggestionPopover({
    required ColorScheme colorScheme,
    required double maxHeight,
  }) {
    final useDenseListTiles = Theme.of(context).visualDensity.vertical < 0;
    final isMention = _popoverType == ChatComposerPopoverType.mention;
    final suggestions = isMention
        ? _mentionSuggestions
              .map(
                (item) => (
                  title: item.value,
                  subtitle: item.subtitle,
                  icon: item.type == ChatComposerSuggestionType.file
                      ? Symbols.insert_drive_file
                      : Symbols.smart_toy,
                  badge: item.type == ChatComposerSuggestionType.file
                      ? 'file'
                      : 'agent',
                ),
              )
              .toList(growable: false)
        : _slashSuggestions
              .map(
                (item) => (
                  title: '/${item.name}',
                  subtitle: item.description,
                  icon: item.isBuiltin ? Symbols.bolt : Symbols.extension,
                  badge: item.source,
                ),
              )
              .toList(growable: false);

    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      skipTraversal: true,
      child: Material(
        key: ValueKey<String>('composer_popover_panel_${_popoverType.name}'),
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _isLoadingSuggestions && suggestions.isEmpty
              ? const SizedBox(
                  height: 72,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : suggestions.isEmpty
              ? SizedBox(
                  height: 72,
                  child: Center(child: Text(context.l10n.cannedNoSuggestions)),
                )
              : ListView.builder(
                  key: ValueKey<String>(
                    'composer_popover_${_popoverType.name}',
                  ),
                  primary: false,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  shrinkWrap: false,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    final selected = index == _activeSuggestionIndex;
                    return ListTile(
                      dense: useDenseListTiles,
                      selected: selected,
                      leading: Icon(item.icon, size: 18),
                      title: Text(item.title),
                      subtitle: item.subtitle == null || item.subtitle!.isEmpty
                          ? null
                          : Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.badge,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      onTap: () {
                        _setState(() {
                          _activeSuggestionIndex = index;
                        });
                        unawaited(_applyActiveSuggestion());
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
