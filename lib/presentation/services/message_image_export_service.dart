import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logging/app_logger.dart';

/// Maximum render height in logical pixels for a single capture.
/// Messages taller than this are rejected to avoid GPU texture overflow.
const _maxCaptureHeight = 4096.0;

/// Pixel ratio for the captured image — balances sharpness and memory.
const _capturePixelRatio = 2.5;

/// Result of a share-image export attempt.
enum MessageImageExportResult {
  /// Image captured and share sheet invoked successfully.
  shared,

  /// The message widget is too tall for a safe GPU capture.
  tooTall,

  /// The RepaintBoundary has not been laid out yet (no render object).
  notLaidOut,

  /// An unexpected error occurred during capture or sharing.
  failed,
}

/// Service that captures a [RepaintBoundary] widget as a PNG image and
/// invokes the platform share sheet. Designed for single-message image
/// export from the chat view.
class MessageImageExportService {
  /// Captures the widget tree under [boundaryKey] as a PNG, writes it to a
  /// temporary file, and opens the native share sheet with [subject] as the
  /// share title.
  ///
  /// Returns [MessageImageExportResult.shared] on success, or a specific
  /// failure code so the caller can show an appropriate user-facing message.
  static Future<MessageImageExportResult> captureAndShare({
    required GlobalKey boundaryKey,
    String? subject,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null) {
      return MessageImageExportResult.notLaidOut;
    }

    final size = boundary.size;
    if (size.height > _maxCaptureHeight) {
      return MessageImageExportResult.tooTall;
    }

    ui.Image? image;
    try {
      image = await boundary.toImage(pixelRatio: _capturePixelRatio);
    } catch (e) {
      AppLogger.error('MessageImageExport: toImage failed', error: e);
      return MessageImageExportResult.failed;
    }

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return MessageImageExportResult.failed;
      }

      final buffer = byteData.buffer;
      final tempDir = await getTemporaryDirectory();
      // Static filename overwrites previous export, preventing unbounded
      // cache growth from timestamped files accumulating in the temp dir.
      final file = File('${tempDir.path}/codewalk_message_share.png');
      await file.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      await Share.shareXFiles([XFile(file.path)], subject: subject);

      return MessageImageExportResult.shared;
    } catch (e) {
      AppLogger.error('MessageImageExport: share failed', error: e);
      return MessageImageExportResult.failed;
    } finally {
      image.dispose();
    }
  }
}
