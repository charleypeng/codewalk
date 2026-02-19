import 'package:equatable/equatable.dart';

import 'chat_session.dart';

class ChatComposerDraft extends Equatable {
  const ChatComposerDraft({
    required this.text,
    this.attachments = const <FileInputPart>[],
    this.shellMode = false,
  });

  final String text;
  final List<FileInputPart> attachments;
  final bool shellMode;

  bool get hasContent {
    if (text.trim().isNotEmpty) {
      return true;
    }
    if (shellMode) {
      return false;
    }
    return attachments.isNotEmpty;
  }

  @override
  List<Object?> get props => [text, attachments, shellMode];
}
