// lib/features/movies/providers/movies_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/supabase_service.dart';

// ─── All Movies ───────────────────────────────────────────────────────────────

class MoviesState {
  final List<Movie> allMovies;
  final bool isLoading;
  final String? error;

  const MoviesState({
    this.allMovies = const [],
    this.isLoading = false,
    this.error,
  });

  MoviesState copyWith({
    List<Movie>? allMovies,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      MoviesState(
        allMovies: allMovies ?? this.allMovies,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class MoviesNotifier extends StateNotifier<MoviesState> {
  MoviesNotifier() : super(const MoviesState()) {
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await SupabaseService.client
          .from(AppConstants.moviesTable)
          .select()
          .order('rating', ascending: false);

      final movies =
          (data as List<dynamic>).map((e) => Movie.fromMap(e)).toList();
      state = state.copyWith(allMovies: movies, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load movies: $e');
    }
  }
}

final moviesProvider =
    StateNotifierProvider<MoviesNotifier, MoviesState>(
  (ref) => MoviesNotifier(),
);

// ─── Search Query ─────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Genre Filter ─────────────────────────────────────────────────────────────

final selectedGenreProvider = StateProvider<String>((ref) => 'All');

// ─── Filtered Movies ──────────────────────────────────────────────────────────

final filteredMoviesProvider = Provider<List<Movie>>((ref) {
  final all = ref.watch(moviesProvider).allMovies;
  final q = ref.watch(searchQueryProvider).toLowerCase().trim();
  final genre = ref.watch(selectedGenreProvider);

  return all.where((m) {
    final matchQ = q.isEmpty ||
        m.title.toLowerCase().contains(q) ||
        m.genres.any((g) => g.toLowerCase().contains(q)) ||
        m.actors.any((a) => a.toLowerCase().contains(q)) ||
        (m.director?.toLowerCase().contains(q) ?? false);
    final matchG = genre == 'All' || m.genres.contains(genre);
    return matchQ && matchG;
  }).toList();
});
