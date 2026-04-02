// lib/features/movies/providers/favorites_provider.dart
//
// Content-Based Filtering Algorithm (genres + actors):
//  1. Collect all movies the user favorited OR rated >= 3.5
//  2. Build genre_weight[genre]++ and actor_weight[actor]++ for each liked movie
//  3. For each unseen movie: score = Σ genre_weight[g] * GENRE_FACTOR
//                                   + Σ actor_weight[a] * ACTOR_FACTOR
//  4. Normalise & sort descending → top-15 recommendations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/supabase_service.dart';
import 'movies_provider.dart';

// Weights for recommendation scoring
const _genreFactor = 2.0;
const _actorFactor = 3.0; // actors contribute more (more specific signal)

// ─── Favorites ────────────────────────────────────────────────────────────────

class FavoritesState {
  final Set<int> favoriteIds;
  final bool isLoading;

  const FavoritesState({
    this.favoriteIds = const {},
    this.isLoading = false,
  });

  bool isFavorite(int id) => favoriteIds.contains(id);

  FavoritesState copyWith({Set<int>? favoriteIds, bool? isLoading}) =>
      FavoritesState(
        favoriteIds: favoriteIds ?? this.favoriteIds,
        isLoading: isLoading ?? this.isLoading,
      );
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final data = await SupabaseService.client
          .from(AppConstants.favoritesTable)
          .select('movie_id')
          .eq('user_id', uid);

      final ids = (data as List<dynamic>)
          .map((e) => e['movie_id'] as int)
          .toSet();
      state = state.copyWith(favoriteIds: ids, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleFavorite(Movie movie) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    final isFav = state.isFavorite(movie.id);

    // Optimistic update
    final newIds = Set<int>.from(state.favoriteIds);
    if (isFav) {
      newIds.remove(movie.id);
    } else {
      newIds.add(movie.id);
    }
    state = state.copyWith(favoriteIds: newIds);

    try {
      if (isFav) {
        await SupabaseService.client
            .from(AppConstants.favoritesTable)
            .delete()
            .eq('user_id', uid)
            .eq('movie_id', movie.id);
      } else {
        await SupabaseService.client.from(AppConstants.favoritesTable).insert({
          'user_id': uid,
          'movie_id': movie.id,
        });
      }
    } catch (_) {
      // Rollback on error
      state = state.copyWith(favoriteIds: Set<int>.from(state.favoriteIds)
        ..remove(movie.id));
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(),
);

// ─── Ratings ──────────────────────────────────────────────────────────────────

class RatingsNotifier extends StateNotifier<Map<int, double>> {
  RatingsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      final data = await SupabaseService.client
          .from(AppConstants.ratingsTable)
          .select('movie_id, rating')
          .eq('user_id', uid);

      final map = <int, double>{};
      for (final row in (data as List<dynamic>)) {
        map[row['movie_id'] as int] =
            (row['rating'] as num).toDouble();
      }
      state = map;
    } catch (_) {}
  }

  Future<void> rate(int movieId, double rating) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    // Optimistic update
    state = {...state, movieId: rating};

    try {
      await SupabaseService.client
          .from(AppConstants.ratingsTable)
          .upsert({
        'user_id': uid,
        'movie_id': movieId,
        'rating': rating,
      }, onConflict: 'user_id,movie_id');
    } catch (_) {}
  }

  double? getRating(int movieId) => state[movieId];
}

final ratingsProvider =
    StateNotifierProvider<RatingsNotifier, Map<int, double>>(
  (ref) => RatingsNotifier(),
);

// ─── Favorite Movies (full objects) ───────────────────────────────────────────

final favoriteMoviesProvider = Provider<List<Movie>>((ref) {
  final all = ref.watch(moviesProvider).allMovies;
  final favIds = ref.watch(favoritesProvider).favoriteIds;
  return all.where((m) => favIds.contains(m.id)).toList();
});

// ─── Content-Based Recommendation Engine ─────────────────────────────────────
//
// Signal sources:
//  • Genres (factor ×2) – broad category preference
//  • Actors (factor ×3) – stronger, more specific preference
//
// Liked movies = favorites ∪ {rated ≥ 3.5}
// Score(movie) = Σ genre_weight[g]×GENRE_FACTOR + Σ actor_weight[a]×ACTOR_FACTOR

final recommendationsProvider = Provider<List<Movie>>((ref) {
  final all = ref.watch(moviesProvider).allMovies;
  final favIds = ref.watch(favoritesProvider).favoriteIds;
  final ratings = ref.watch(ratingsProvider);

  if (all.isEmpty) return [];

  // ── Build liked set ──────────────────────────────────────────────────────
  final likedIds = <int>{
    ...favIds,
    ...ratings.entries
        .where((e) => e.value >= 3.5)
        .map((e) => e.key),
  };

  // ── Build preference profile ─────────────────────────────────────────────
  final Map<String, double> genreWeights = {};
  final Map<String, double> actorWeights = {};

  for (final movie in all.where((m) => likedIds.contains(m.id))) {
    // Weight liked movies by rating bonus (if rated)
    final ratingBonus = ratings[movie.id] != null
        ? (ratings[movie.id]! / 5.0) // 0..1 multiplier
        : 1.0;

    for (final g in movie.genres) {
      genreWeights[g] = (genreWeights[g] ?? 0) + ratingBonus;
    }
    for (final a in movie.actors) {
      actorWeights[a] = (actorWeights[a] ?? 0) + ratingBonus;
    }
  }

  // ── Default: top-rated if no interactions ────────────────────────────────
  if (genreWeights.isEmpty && actorWeights.isEmpty) {
    final sorted = [...all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(15).toList();
  }

  // ── Score unseen movies ──────────────────────────────────────────────────
  final unseen = all.where((m) => !likedIds.contains(m.id)).toList();

  final scored = unseen.map((movie) {
    double score = 0;
    for (final g in movie.genres) {
      score += (genreWeights[g] ?? 0) * _genreFactor;
    }
    for (final a in movie.actors) {
      score += (actorWeights[a] ?? 0) * _actorFactor;
    }
    return _Scored(movie, score);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return scored.take(15).map((s) => s.movie).toList();
});

class _Scored {
  final Movie movie;
  final double score;
  _Scored(this.movie, this.score);
}

// ─── Genre Stats (for chart) ──────────────────────────────────────────────────

final genreStatsProvider = Provider<Map<String, int>>((ref) {
  final all = ref.watch(moviesProvider).allMovies;
  final favIds = ref.watch(favoritesProvider).favoriteIds;
  final ratings = ref.watch(ratingsProvider);

  final interacted = <int>{...favIds, ...ratings.keys};
  final Map<String, int> stats = {};

  for (final movie in all.where((m) => interacted.contains(m.id))) {
    for (final g in movie.genres) {
      stats[g] = (stats[g] ?? 0) + 1;
    }
  }
  return stats;
});

// ─── Actor Stats (for chart) ──────────────────────────────────────────────────

final actorStatsProvider = Provider<Map<String, int>>((ref) {
  final all = ref.watch(moviesProvider).allMovies;
  final favIds = ref.watch(favoritesProvider).favoriteIds;
  final ratings = ref.watch(ratingsProvider);

  final interacted = <int>{...favIds, ...ratings.keys};
  final Map<String, int> stats = {};

  for (final movie in all.where((m) => interacted.contains(m.id))) {
    for (final a in movie.actors) {
      stats[a] = (stats[a] ?? 0) + 1;
    }
  }
  return stats;
});
