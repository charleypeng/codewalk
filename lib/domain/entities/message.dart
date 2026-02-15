import 'package:equatable/equatable.dart';

/// Technical comment translated to English.
enum MessageRole { user, assistant }

/// Technical comment translated to English.
abstract class Message extends Equatable {

  const Message({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.time,
  });
  final String id;
  final String sessionId;
  final MessageRole role;
  final MessageTime time;
}

/// Technical comment translated to English.
class UserMessage extends Message {
  const UserMessage({
    required super.id,
    required super.sessionId,
    required super.time,
  }) : super(role: MessageRole.user);

  @override
  List<Object> get props => [id, sessionId, role, time];
}

/// Technical comment translated to English.
class AssistantMessage extends Message {

  const AssistantMessage({
    required super.id,
    required super.sessionId,
    required super.time,
    this.error,
    required this.system,
    required this.modelId,
    required this.providerId,
    required this.mode,
    required this.path,
    this.summary,
    required this.cost,
    required this.tokens,
  }) : super(
         role: MessageRole.assistant,
       );
  final MessageError? error;
  final List<String> system;
  final String modelId;
  final String providerId;
  final String mode;
  final MessagePath path;
  final bool? summary;
  final double cost;
  final MessageTokens tokens;

  @override
  List<Object?> get props => [
    id,
    sessionId,
    role,
    time,
    error,
    system,
    modelId,
    providerId,
    mode,
    path,
    summary,
    cost,
    tokens,
  ];
}

/// Technical comment translated to English.
class MessageTime extends Equatable {

  const MessageTime({required this.created, this.completed});
  final int created;
  final int? completed;

  @override
  List<Object?> get props => [created, completed];
}

/// Technical comment translated to English.
class MessagePath extends Equatable {

  const MessagePath({required this.cwd, required this.root});
  final String cwd;
  final String root;

  @override
  List<Object> get props => [cwd, root];
}

/// Technical comment translated to English.
class MessageTokens extends Equatable {

  const MessageTokens({
    required this.input,
    required this.output,
    required this.reasoning,
    required this.cache,
  });
  final int input;
  final int output;
  final int reasoning;
  final TokenCache cache;

  @override
  List<Object> get props => [input, output, reasoning, cache];
}

/// Technical comment translated to English.
class TokenCache extends Equatable {

  const TokenCache({required this.read, required this.write});
  final int read;
  final int write;

  @override
  List<Object> get props => [read, write];
}

/// Technical comment translated to English.
abstract class MessageError extends Equatable {

  const MessageError({required this.name});
  final String name;
}

/// Technical comment translated to English.
class ProviderAuthError extends MessageError {

  const ProviderAuthError({required this.providerId, required this.message})
    : super(name: 'ProviderAuthError');
  final String providerId;
  final String message;

  @override
  List<Object> get props => [name, providerId, message];
}

/// Technical comment translated to English.
class UnknownError extends MessageError {

  const UnknownError({required this.message}) : super(name: 'UnknownError');
  final String message;

  @override
  List<Object> get props => [name, message];
}

/// Technical comment translated to English.
class MessageOutputLengthError extends MessageError {
  const MessageOutputLengthError() : super(name: 'MessageOutputLengthError');

  @override
  List<Object> get props => [name];
}

/// Technical comment translated to English.
class MessageAbortedError extends MessageError {
  const MessageAbortedError() : super(name: 'MessageAbortedError');

  @override
  List<Object> get props => [name];
}
