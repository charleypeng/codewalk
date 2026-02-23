part of '../chat_message_widget.dart';

/// File attachment rendering with image preview and action handling.
extension _ChatMessageFilePartBuilder on _ChatMessageWidgetState {
  Widget _buildFilePart(BuildContext context, FilePart part) {
    final sourcePath = part.fileSource?.path ?? part.symbolSource?.path;
    final isInlineDataAttachment = _isInlineDataAttachment(part.url);
    final imagePreview = _buildImageAttachmentPreview(context, part);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppShapes.borderSmall,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePreview != null) ...[
            imagePreview,
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                _getFileIcon(part.mime),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.filename ?? 'File',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sourcePath != null && sourcePath.trim().isNotEmpty)
                      Text(
                        sourcePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  unawaited(
                    _handleFilePartAction(
                      context,
                      url: part.url,
                      sourcePath: sourcePath,
                      mimeType: part.mime,
                      filename: part.filename,
                    ),
                  );
                },
                icon: Icon(
                  isInlineDataAttachment
                      ? Symbols.download_rounded
                      : Symbols.open_in_new_rounded,
                ),
                tooltip: isInlineDataAttachment ? 'Save File' : 'Open File',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildImageAttachmentPreview(BuildContext context, FilePart part) {
    if (!part.mime.toLowerCase().startsWith('image/')) {
      return null;
    }

    final image = _resolveAttachmentImageWidget(part.url);
    if (image == null) {
      return null;
    }

    return ClipRRect(
      key: ValueKey<String>('file_image_preview_${part.id}'),
      borderRadius: AppShapes.borderSmall,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220, minHeight: 120),
        child: Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: image,
        ),
      ),
    );
  }

  Widget? _resolveAttachmentImageWidget(String rawUrl) {
    final trimmedUrl = rawUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmedUrl);
    if (parsed == null) {
      return null;
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme == 'data') {
      final bytes = _decodeDataUriBytes(trimmedUrl);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(trimmedUrl, fit: BoxFit.cover);
    }
    return null;
  }

  Uint8List? _decodeDataUriBytes(String dataUrl) {
    try {
      return Uint8List.fromList(UriData.parse(dataUrl).contentAsBytes());
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleFilePartAction(
    BuildContext context, {
    required String url,
    required String? sourcePath,
    required String mimeType,
    required String? filename,
  }) async {
    final result = await file_part_action.handleFilePartAction(
      url: url,
      sourcePath: sourcePath,
      mimeType: mimeType,
      filename: filename,
    );
    if (!context.mounted || result.message == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message!)));
  }

  bool _isInlineDataAttachment(String url) {
    if (url.trim().isEmpty) {
      return false;
    }
    final parsed = Uri.tryParse(url.trim());
    return parsed?.scheme.toLowerCase() == 'data';
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) {
      return Symbols.image;
    } else if (mime.startsWith('video/')) {
      return Symbols.video_file;
    } else if (mime.startsWith('audio/')) {
      return Symbols.audio_file;
    } else if (mime.contains('pdf')) {
      return Symbols.picture_as_pdf;
    } else if (mime.contains('text/')) {
      return Symbols.text_snippet;
    } else {
      return Symbols.insert_drive_file;
    }
  }
}
