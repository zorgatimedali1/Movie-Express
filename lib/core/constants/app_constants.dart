// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = '';
  static const String supabaseAnonKey =
      '';

  // ── Gemini API (direct) ───────────────────────────────────────────────────
  static const String geminiApiKey = 'AIzaSyDmEuR-u4kYyqDRik5qxYfr-p-nU__S-mk';

  // ── Groq API ──────────────────────────────────────────────────────────────
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';

  // ── Tables ────────────────────────────────────────────────────────────────
  static const String moviesTable = 'movies';
  static const String favoritesTable = 'user_favorites';
  static const String ratingsTable = 'user_ratings';
  static const String profilesTable = 'profiles';

  // ── App info ──────────────────────────────────────────────────────────────
  static const String appName = 'MovieRec Express';

  // ── Genres ────────────────────────────────────────────────────────────────
  static const List<String> allGenres = [
    'All',
    'Action',
    'Adventure',
    'Animation',
    'Biography',
    'Comedy',
    'Crime',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
    'War',
  ];
}
