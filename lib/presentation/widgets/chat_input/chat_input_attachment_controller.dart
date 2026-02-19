part of '../chat_input_widget.dart';

extension _ChatInputAttachmentController on _ChatInputWidgetState {
  void _showAttachmentOptions() {
    if (!widget.allowImageAttachment && !widget.allowPdfAttachment) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (widget.allowImageAttachment)
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Select Images'),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_pickImages());
                },
              ),
            if (widget.allowPdfAttachment)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Select PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_pickPdf());
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }
    _appendAttachments(result.files, forcePdf: false);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }
    _appendAttachments(result.files, forcePdf: true);
  }

  void _appendAttachments(List<PlatformFile> files, {required bool forcePdf}) {
    final nextAttachments = <FileInputPart>[];
    for (final file in files) {
      final url = _resolveAttachmentUrl(file, forcePdf: forcePdf);
      if (url == null) {
        continue;
      }
      final mime = forcePdf ? 'application/pdf' : _resolveImageMime(file);
      if (!_isMimeAllowed(mime)) {
        continue;
      }
      nextAttachments.add(
        FileInputPart(
          mime: mime,
          url: url,
          filename: file.name.isEmpty ? null : file.name,
        ),
      );
    }

    if (nextAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid files were selected')),
      );
      return;
    }

    _setState(() {
      final dedupe = <String>{
        for (final existing in _attachments)
          '${existing.mime}|${existing.url}|${existing.filename ?? ""}',
      };
      for (final attachment in nextAttachments) {
        final key =
            '${attachment.mime}|${attachment.url}|'
            '${attachment.filename ?? ""}';
        if (dedupe.add(key)) {
          _attachments.add(attachment);
        }
      }
    });
  }

  bool _isMimeAllowed(String mime) {
    if (mime.startsWith('image/')) {
      return widget.allowImageAttachment;
    }
    if (mime == 'application/pdf') {
      return widget.allowPdfAttachment;
    }
    return false;
  }

  String? _resolveAttachmentUrl(PlatformFile file, {required bool forcePdf}) {
    final mime = forcePdf ? 'application/pdf' : _resolveImageMime(file);
    if (file.bytes case final bytes?) {
      if (bytes.isEmpty) {
        return null;
      }
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return Uri.file(path).toString();
  }

  String _resolveImageMime(PlatformFile file) {
    final ext = (file.extension ?? '').trim().toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/png';
    }
  }
}
