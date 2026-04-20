// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://pbyklrjylelfkmgmadpg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBieWtscmp5bGVsZmttZ21hZHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NjQ3MjUsImV4cCI6MjA5MDQ0MDcyNX0.nliRtcs4H4Fk8N3p2gMfopUcFJ_qmDbZBidN8Ps2Ob0';

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
