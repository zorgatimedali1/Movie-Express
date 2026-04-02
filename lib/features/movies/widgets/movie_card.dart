// lib/features/movies/widgets/movie_card.dart

// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie_model.dart';
import '../providers/favorites_provider.dart';
import '../../../core/theme/app_theme.dart';

const _fallbackColors = [
  Color(0xFF1A237E),
  Color(0xFF4A148C),
  Color(0xFF880E4F),
  Color(0xFF1B5E20),
  Color(0xFFE65100),
  Color(0xFF006064),
  Color(0xFF37474F),
  Color(0xFF3E2723),
];

class MovieCard extends ConsumerWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  Color get _color => _fallbackColors[movie.id % _fallbackColors.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).isFavorite(movie.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster ──────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Poster image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: movie.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _shimmer(),
                            errorWidget: (_, __, ___) => _fallbackPoster(),
                          )
                        : _fallbackPoster(),
                  ),

                  // Year badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child:
                        _badge('${movie.year}', Colors.black.withOpacity(0.65)),
                  ),

                  // Favorite button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(movie),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppTheme.primaryColor : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Rating badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 11, color: Colors.black),
                          const SizedBox(width: 2),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.genres.take(2).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPoster() => Container(
        width: double.infinity,
        height: double.infinity,
        color: _color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(movie.initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(movie.primaryGenre,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      );

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: AppTheme.cardColor,
        highlightColor: AppTheme.surfaceColor,
        child: Container(color: AppTheme.cardColor),
      );

  static Widget _badge(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      );
}
