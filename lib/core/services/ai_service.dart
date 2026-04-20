import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

// Groq — free, fast, OpenAI-compatible
const _kGroqUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _kModel = 'llama-3.1-8b-instant'; // free & fast on Groq

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ── Movie Assistant Chatbot ───────────────────────────────────────────────

  Future<String> chatWithMovieAssistant({
    required String userMessage,
    required List<Map<String, dynamic>> movies,
    required List<Map<String, String>> history,
  }) async {
    const maxMovies = 58;
    final displayed = movies.take(maxMovies).toList();
    final moviesContext = displayed.map((m) {
      final genres = (m['genres'] as List?)?.join(', ') ?? '';
      return '- ${m['title']} (${m['year']}) | $genres | ⭐${m['rating']}';
    }).join('\n');

    final systemPrompt = '''Tu es CineBot, un assistant cinéma intelligent et sympathique.
Tu aides les utilisateurs à trouver des films dans ce catalogue.

CATALOGUE (${movies.length} films) :
$moviesContext

RÈGLES :
- Réponds toujours en français
- Recommande UNIQUEMENT des films présents dans la liste ci-dessus
- Maximum 3 recommandations par réponse
- Sois chaleureux, concis et enthousiaste
- Comprends les fautes de frappe et les demandes floues (ex: "comdie" = comédie)
- Si aucun film ne correspond, dis-le honnêtement et propose une alternative proche''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': userMessage},
    ];

    return _callGroq(messages: messages, maxTokens: 500);
  }

  // ── Profile Analysis ─────────────────────────────────────────────────────

  Future<String> analyzeUserProfile({
    required Map<String, double> genreWeights,
    required Map<String, double> actorWeights,
    required int totalFavorites,
    required int totalRatings,
    required double averageRating,
  }) async {
    final topGenres = _topEntries(genreWeights, 5);
    final topActors = _topEntries(actorWeights, 5);

    if (topGenres.isEmpty && topActors.isEmpty) {
      return "Commence à noter des films et ajouter des favoris pour débloquer ton analyse cinéma personnalisée ! 🎬";
    }

    final prompt = '''Génère une analyse de profil cinématographique personnalisée en français.

PROFIL :
- Genres préférés : ${topGenres.join(', ')}
- Acteurs favoris : ${topActors.isNotEmpty ? topActors.join(', ') : 'variés'}
- Films en favoris : $totalFavorites
- Films notés : $totalRatings
- Note moyenne : ${averageRating.toStringAsFixed(1)}/5

3-4 phrases max. Donne un "type" de cinéphile créatif. Termine par un défi cinéma. Max 2 emojis.''';

    return _callGroq(
      messages: [
        {'role': 'user', 'content': prompt}
      ],
      maxTokens: 300,
    );
  }

  // ── Groq API call ────────────────────────────────────────────────────────

  Future<String> _callGroq({
    required List<Map<String, dynamic>> messages,
    int maxTokens = 500,
  }) async {
    final response = await http.post(
      Uri.parse(_kGroqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
      },
      body: jsonEncode({
        'model': _kModel,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['choices']?[0]?['message']?['content'] as String?;
    return text?.trim() ?? "Désolé, je ne peux pas répondre pour le moment.";
  }

  List<String> _topEntries(Map<String, double> map, int n) {
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }
}
