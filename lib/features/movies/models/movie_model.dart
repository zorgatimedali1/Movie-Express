// lib/features/movies/models/movie_model.dart

class Movie {
  final int id;
  final String title;
  final List<String> genres;
  final List<String> actors;
  final String? director;
  final int year;
  final double rating;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;

  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.actors,
    this.director,
    required this.year,
    required this.rating,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
  });

  /// First letter of title for fallback avatar
  String get initial => title.isNotEmpty ? title[0].toUpperCase() : '?';

  /// Primary genre
  String get primaryGenre => genres.isNotEmpty ? genres.first : 'Unknown';

  factory Movie.fromMap(Map<String, dynamic> map) => Movie(
        id: map['id'] as int,
        title: map['title'] as String? ?? '',
        genres: _toStringList(map['genres']),
        actors: _toStringList(map['actors']),
        director: map['director'] as String?,
        year: map['year'] as int? ?? 2000,
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        overview: map['overview'] as String?,
        posterUrl: map['poster_url'] as String?,
        backdropUrl: map['backdrop_url'] as String?,
      );

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  @override
  bool operator ==(Object other) => other is Movie && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Movie(id: $id, title: $title)';
}
