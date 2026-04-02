// lib/features/movies/screens/home_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/movies_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/genre_chip.dart';
import 'movie_detail_screen.dart';
import 'favorites_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  static const _tabs = [
    _MoviesTab(),
    _RecommendationsTab(),
    FavoritesScreen(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('🎬 MovieRec Express'),
        ),
        body: IndexedStack(index: _tab, children: _tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.movie_outlined),
                activeIcon: Icon(Icons.movie),
                label: 'Movies'),
            BottomNavigationBarItem(
                icon: Icon(Icons.recommend_outlined),
                activeIcon: Icon(Icons.recommend),
                label: 'For You'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 – MOVIES
// ═══════════════════════════════════════════════════════════════════════════════

class _MoviesTab extends ConsumerWidget {
  const _MoviesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moviesProvider);
    final filtered = ref.watch(filteredMoviesProvider);
    final genre = ref.watch(selectedGenreProvider);
    final query = ref.watch(searchQueryProvider);

    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.read(moviesProvider.notifier).fetchMovies(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search title, genre or actor…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          ref.read(searchQueryProvider.notifier).state = '',
                    )
                  : null,
            ),
          ),
        ),

        // Genre chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: AppConstants.allGenres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = AppConstants.allGenres[i];
              return GenreChip(
                genre: g,
                isSelected: genre == g,
                onTap: () => ref.read(selectedGenreProvider.notifier).state = g,
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} movies',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 6),

        // Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No movies found.',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.60,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => MovieCard(
                    movie: filtered[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) =>
                              MovieDetailScreen(movie: filtered[i])),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 – RECOMMENDATIONS (Content-Based Filtering)
// ═══════════════════════════════════════════════════════════════════════════════

class _RecommendationsTab extends ConsumerWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recs = ref.watch(recommendationsProvider);
    final favIds = ref.watch(favoritesProvider).favoriteIds;
    final ratings = ref.watch(ratingsProvider);
    final hasInteraction = favIds.isNotEmpty || ratings.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF880E4F), AppTheme.primaryColor],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('AI Recommendations',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasInteraction
                      ? 'Content-Based Filtering — genres & actors you love'
                      : 'Top-rated picks while we learn your taste',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),

          // Algorithm explanation chip row
          const SizedBox(height: 14),
          if (hasInteraction)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoPill(Icons.category_outlined, 'Genre signals ×2'),
                _infoPill(Icons.people_outline, 'Actor signals ×3'),
                _infoPill(Icons.star_outline, 'Rating bonus applied'),
              ],
            ),

          if (!hasInteraction) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.accentColor.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppTheme.accentColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add favorites ♥ or rate movies ★ to get personalized recommendations based on genres and actors!',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.60,
            ),
            itemCount: recs.length,
            itemBuilder: (ctx, i) => MovieCard(
              movie: recs[i],
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: recs[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.accentColor),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 – PROFILE
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final favCount = ref.watch(favoritesProvider).favoriteIds.length;
    final ratingCount = ref.watch(ratingsProvider).length;
    final genreStats = ref.watch(genreStatsProvider);
    final actorStats = ref.watch(actorStatsProvider);

    final name = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'User';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.4)),
                        ),
                        child: const Text('Supabase Auth ✓',
                            style: TextStyle(
                                color: AppTheme.primaryColor, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats ────────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                  icon: Icons.favorite, label: 'Favorites', value: '$favCount'),
              const SizedBox(width: 10),
              _StatCard(
                  icon: Icons.star, label: 'Rated', value: '$ratingCount'),
              const SizedBox(width: 10),
              _StatCard(
                  icon: Icons.category,
                  label: 'Genres',
                  value: '${genreStats.length}'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Genre chart ───────────────────────────────────────────────
          if (genreStats.isNotEmpty) ...[
            _sectionTitle('Top Genres'),
            const SizedBox(height: 4),
            const Text('Content-Based Filtering — genre signals',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 14),
            SizedBox(
                height: 200, child: _BarChart(stats: genreStats, maxBars: 6)),
            const SizedBox(height: 24),
          ],

          // ── Actor chart ───────────────────────────────────────────────
          if (actorStats.isNotEmpty) ...[
            _sectionTitle('Favourite Actors'),
            const SizedBox(height: 4),
            const Text('Content-Based Filtering — actor signals (×3 weight)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 14),
            SizedBox(
                height: 200,
                child: _BarChart(
                    stats: actorStats,
                    maxBars: 5,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 28),
          ],

          // ── Sign out ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardColor,
                  title: const Text('Sign Out',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to sign out?',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authProvider.notifier).signOut();
                      },
                      child: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _BarChart extends StatelessWidget {
  final Map<String, int> stats;
  final int maxBars;
  final Color color;

  const _BarChart({
    required this.stats,
    this.maxBars = 6,
    this.color = AppTheme.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(maxBars).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (top.first.value + 1).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= top.length) {
                  return const SizedBox.shrink();
                }
                final label = top[i].key;
                // shorten long actor names
                final short =
                    label.length > 10 ? label.split(' ').first : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(
          top.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: top[i].value.toDouble(),
                color: color,
                width: 22,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
