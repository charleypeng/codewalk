part of '../chat_message_widget.dart';

/// Text part rendering with markdown support and clipboard actions.
extension _ChatMessageTextPartBuilder on _ChatMessageWidgetState {
  Widget _buildTextPart(BuildContext context, TextPart part) {
    // Don't display if text is empty or only whitespace
    if (part.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final textForRender = _truncatePreview(
      part.text,
      maxChars: _ChatMessageWidgetState._maxMarkdownCharsForRichRender,
      reason: 'Large message preview truncated for app stability.',
    );
    final usePlainText = textForRender != part.text;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (usePlainText)
            Text(textForRender, style: Theme.of(context).textTheme.bodyMedium)
          else
            MarkdownBody(
              data: textForRender,
              softLineBreak: true,
              styleSheet: _resolveMarkdownStyleSheet(context),
              builders: <String, MarkdownElementBuilder>{
                'pre': _MarkdownCodeBlockTapBuilder(
                  onTapCode: (code) => _copyTextToClipboard(context, code),
                ),
                'code': _MarkdownInlineCodeTapBuilder(
                  onTapCode: (code) => _copyTextToClipboard(context, code),
                ),
              },
              onTapLink: (text, href, title) {
                final normalizedHref = href?.trim();
                if (normalizedHref == null || normalizedHref.isEmpty) {
                  return;
                }
                unawaited(_openMarkdownLink(context, normalizedHref));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _composeMessageCopyText(ChatMessage message) {
    final parts = message.parts
        .whereType<TextPart>()
        .map((part) => part.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    return parts.join('\n\n');
  }

  void _copyTextToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _openMarkdownLink(BuildContext context, String href) async {
    var uri = Uri.tryParse(href);
    if (uri == null) {
      _showLinkOpenFeedback(context, 'Invalid link format');
      return;
    }
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$href');
    }
    if (uri == null || uri.host.trim().isEmpty) {
      _showLinkOpenFeedback(context, 'Invalid link format');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLinkOpenFeedback(context, 'Unable to open link');
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Failed to open markdown link',
        error: error,
        stackTrace: stackTrace,
      );
      _showLinkOpenFeedback(context, 'Unable to open link');
    }
  }

  void _showLinkOpenFeedback(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MarkdownCodeBlockTapBuilder extends MarkdownElementBuilder {
  _MarkdownCodeBlockTapBuilder({required this.onTapCode});

  final ValueChanged<String> onTapCode;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    if (code.trim().isEmpty) {
      return null;
    }
    final style =
        preferredStyle ??
        parentStyle ??
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapCode(code),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: Text(code, style: style),
      ),
    );
  }
}

class _MarkdownInlineCodeTapBuilder extends MarkdownElementBuilder {
  _MarkdownInlineCodeTapBuilder({required this.onTapCode});

  final ValueChanged<String> onTapCode;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    if (code.trim().isEmpty) {
      return null;
    }
    final style =
        preferredStyle ??
        parentStyle ??
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapCode(code),
      child: Text(code, style: style),
    );
  }
}
