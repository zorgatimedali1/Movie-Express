import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant }

@immutable
class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;
  final bool isLoading; // true while waiting for Claude's response

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.isLoading = false,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.user,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.assistant(String content, {bool isLoading = false}) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        isLoading: isLoading,
      );

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
        id: id,
        content: content ?? this.content,
        role: role,
        createdAt: createdAt,
        isLoading: isLoading ?? this.isLoading,
      );

  /// Convert to Anthropic API messages format
  Map<String, String> toApiMap() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}
