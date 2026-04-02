// lib/features/movies/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';
import '../../../core/theme/app_theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(favoriteMoviesProvider);
    final isLoading = ref.watch(favoritesProvider).isLoading;

    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryColor));
    }

    if (movies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('No favorites yet',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 18)),
            SizedBox(height: 8),
            Text('Tap ♥ on any movie to save it here',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${movies.length} favorite${movies.length == 1 ? '' : 's'}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.60,
              ),
              itemCount: movies.length,
              itemBuilder: (context, i) => MovieCard(
                movie: movies[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MovieDetailScreen(movie: movies[i])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
