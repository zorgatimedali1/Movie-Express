import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// AI Profile Analysis Provider
// ────────────────────────────────────────────────────────────────────────────

final _profileAnalysisProvider =
    StateNotifierProvider.autoDispose<_AnalysisNotifier, AsyncValue<String?>>(
        (_) => _AnalysisNotifier());

class _AnalysisNotifier extends StateNotifier<AsyncValue<String?>> {
  _AnalysisNotifier() : super(const AsyncValue.data(null));

  Future<void> analyze({
    required Map<String, double> genreWeights,
    required Map<String, double> actorWeights,
    required int totalFavorites,
    required int totalRatings,
    required double averageRating,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await AIService().analyzeUserProfile(
        genreWeights: genreWeights,
        actorWeights: actorWeights,
        totalFavorites: totalFavorites,
        totalRatings: totalRatings,
        averageRating: averageRating,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

// ────────────────────────────────────────────────────────────────────────────
// ProfileAnalysisCard — drop this anywhere in your profile screen
//
// Usage example (inside your existing ProfileScreen widget):
//
//   ProfileAnalysisCard(
//     genreWeights: genreWeightsMap,       // Map<String,double>
//     actorWeights: actorWeightsMap,        // Map<String,double>
//     totalFavorites: favorites.length,
//     totalRatings: ratings.length,
//     averageRating: avgRating,
//   ),
// ────────────────────────────────────────────────────────────────────────────

class ProfileAnalysisCard extends ConsumerWidget {
  const ProfileAnalysisCard({
    super.key,
    required this.genreWeights,
    required this.actorWeights,
    required this.totalFavorites,
    required this.totalRatings,
    required this.averageRating,
  });

  final Map<String, double> genreWeights;
  final Map<String, double> actorWeights;
  final int totalFavorites;
  final int totalRatings;
  final double averageRating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(_profileAnalysisProvider);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse IA de ton profil',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Découvre ton type de cinéphile',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Content ───────────────────────────────────────────
            analysisState.when(
              data: (text) => text == null
                  ? _AnalyzeButton(
                      onTap: () => ref
                          .read(_profileAnalysisProvider.notifier)
                          .analyze(
                            genreWeights: genreWeights,
                            actorWeights: actorWeights,
                            totalFavorites: totalFavorites,
                            totalRatings: totalRatings,
                            averageRating: averageRating,
                          ),
                    )
                  : _AnalysisResult(
                      text: text,
                      onRefresh: () =>
                          ref.read(_profileAnalysisProvider.notifier).reset(),
                    ),
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(
                message: e.toString(),
                onRetry: () => ref
                    .read(_profileAnalysisProvider.notifier)
                    .analyze(
                      genreWeights: genreWeights,
                      actorWeights: actorWeights,
                      totalFavorites: totalFavorites,
                      totalRatings: totalRatings,
                      averageRating: averageRating,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Analyser mon profil cinéma'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        LinearProgressIndicator(),
        SizedBox(height: 10),
        Text(
          'CineBot analyse ton profil...',
          style: TextStyle(color: Colors.grey, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.text, required this.onRefresh});
  final String text;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Nouvelle analyse', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(height: 6),
        const Text('Impossible d\'analyser le profil.', style: TextStyle(color: Colors.red)),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }
}
