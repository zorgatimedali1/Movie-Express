// lib/features/movies/screens/movie_detail_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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

class MovieDetailScreen extends ConsumerWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  Color get _color => _fallbackColors[movie.id % _fallbackColors.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).isFavorite(movie.id);
    final userRating = ref.watch(ratingsProvider)[movie.id] ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with backdrop ────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.primaryColor : Colors.white,
                ),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(movie);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isFav
                        ? '${movie.title} removed from favorites'
                        : '${movie.title} added to favorites ❤️'),
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop / poster image
                  movie.backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: movie.backdropUrl ?? movie.posterUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppTheme.cardColor,
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(color: AppTheme.cardColor),
                          ),
                          errorWidget: (_, __, ___) => Container(color: _color),
                        )
                      : Container(color: _color),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundColor.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ratingBadge(movie.rating),
                          const SizedBox(height: 4),
                          Text('${movie.year}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Director
                  if (movie.director != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.movie_creation_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('Directed by ${movie.director}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Genres
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: movie.genres.map((g) => _genrePill(g)).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Actors
                  if (movie.actors.isNotEmpty) ...[
                    const Text('Cast',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: movie.actors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            movie.actors[i],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Overview
                  if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                    const Text('Overview',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      movie.overview!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Divider
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),

                  // User rating
                  const Text('Your Rating',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingBar.builder(
                        initialRating: userRating,
                        minRating: 0.5,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 32,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                        itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: AppTheme.accentColor,
                        ),
                        onRatingUpdate: (r) {
                          ref.read(ratingsProvider.notifier).rate(movie.id, r);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Rated ${movie.title}: ${r.toStringAsFixed(1)}/5.0 ⭐'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userRating > 0
                            ? '${userRating.toStringAsFixed(1)} / 5.0'
                            : 'Tap to rate',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      key: ValueKey(userRating >= 3.5),
                      userRating >= 3.5
                          ? '✅ This rating improves your recommendations!'
                          : 'Rate ≥ 3.5 ★ to improve genre & actor suggestions.',
                      style: TextStyle(
                          color: userRating >= 3.5
                              ? Colors.green
                              : AppTheme.textSecondary,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge(double r) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 13, color: Colors.black),
            const SizedBox(width: 4),
            Text(r.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      );

  Widget _genrePill(String g) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14)),
        child: Text(g,
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
      );
}
