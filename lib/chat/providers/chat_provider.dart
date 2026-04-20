import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../../../core/services/ai_service.dart';
import '../../features/movies/providers/movies_provider.dart';

// ── State ────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ── Notifier ─────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ai, this._movies) : super(const ChatState()) {
    // Add welcome message
    state = state.copyWith(messages: [
      ChatMessage.assistant(
        "Salut ! 🎬 Je suis CineBot, ton assistant cinéma. "
        "Dis-moi ce que tu cherches : une émotion, un thème, un genre... "
        "Je trouverai le film parfait pour toi parmi notre catalogue !",
      ),
    ]);
  }

  final AIService _ai;

  /// All movies as raw maps — passed from your movies provider.
  /// Shape: [{title, year, genres: [], actors: [], rating}, ...]
  final List<Map<String, dynamic>> _movies;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    // Add user message
    final userMsg = ChatMessage.user(text.trim());
    final loadingMsg = ChatMessage.assistant('', isLoading: true);

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final history = state.messages
          .where((m) => !m.isLoading)
          .skip(1)
          .map((m) => m.toApiMap())
          .toList();

      final reply = await _ai.chatWithMovieAssistant(
        userMessage: text.trim(),
        movies: _movies,
        history: history,
      );

      // Replace loading bubble with real response
      final updated = List<ChatMessage>.from(state.messages)
        ..removeLast()
        ..add(ChatMessage.assistant(reply));

      state = state.copyWith(messages: updated, isLoading: false);
    } catch (e) {
      final updated = List<ChatMessage>.from(state.messages)..removeLast();
      state = state.copyWith(
        messages: updated,
        isLoading: false,
        errorMessage: 'Oops, une erreur est survenue. ${e.toString()}',
      );
    }
  }

  void clearChat() {
    state = const ChatState();
    state = state.copyWith(messages: [
      ChatMessage.assistant(
        "Nouvelle conversation ! Quel film cherches-tu aujourd'hui ? 🎬",
      ),
    ]);
  }
}

// ── Provider ─────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  final movies = ref.watch(moviesProvider).allMovies;

  final movieMaps = movies
      .map((m) => {
            'title': m.title,
            'year': m.year,
            'genres': m.genres,
            'actors': m.actors,
            'rating': m.rating,
            'overview': m.overview ?? '',
          })
      .toList();

  return ChatNotifier(AIService(), movieMaps);
});
