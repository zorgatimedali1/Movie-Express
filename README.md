# 🎬 MovieRec Express — v2 (Supabase Edition)

> Mini Projet Individuel — Module Développement Mobile Cross-Plateforme (Flutter)  
> Backend : **Supabase** · Auth · PostgreSQL · Row Level Security

---

## 📋 Description

**MovieRec Express** est une application Flutter de recommandation de films.  
- Les films (60) avec **vraies affiches** (TMDB) sont stockés dans **Supabase** (PostgreSQL).
- L'authentification est gérée par **Supabase Auth** (JWT).
- Les favoris et notes sont **synchronisés en ligne** via Supabase.
- L'algorithme de recommandation **Content-Based Filtering** tourne en local, en utilisant les genres **et les acteurs** comme signaux.

---

## 🏗️ Architecture du Projet

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # URL Supabase, clés, noms tables, genres
│   ├── theme/
│   │   └── app_theme.dart            # Thème sombre Material 3
│   └── utils/
│       └── supabase_service.dart     # Singleton client Supabase
│
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   └── auth_provider.dart    # Riverpod StateNotifier → Supabase Auth
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── widgets/
│   │       └── auth_text_field.dart  # Widget réutilisable
│   │
│   └── movies/
│       ├── models/
│       │   └── movie_model.dart      # Modèle Film (+ actors, director, poster_url)
│       ├── providers/
│       │   ├── movies_provider.dart       # Fetch Supabase + recherche + filtre genre
│       │   └── favorites_provider.dart    # Favoris, notes, algo IA, stats
│       ├── screens/
│       │   ├── home_screen.dart      # 4 onglets : Movies/ForYou/Favorites/Profile
│       │   ├── movie_detail_screen.dart   # Détail + cast + notation
│       │   └── favorites_screen.dart
│       └── widgets/
│           ├── movie_card.dart       # Carte avec vraie affiche (cached_network_image)
│           └── genre_chip.dart       # Chip genre animé
│
└── main.dart                         # Supabase.initialize() + ProviderScope + AppGate
```

---

## 🗄️ Schéma Supabase

```sql
── movies ──────────────────────────────────────────────────
  id            SERIAL PRIMARY KEY
  title         TEXT
  genres        TEXT[]        -- ex: ['Action','Sci-Fi']
  actors        TEXT[]        -- ex: ['Keanu Reeves','Carrie-Anne Moss']
  director      TEXT
  year          INTEGER
  rating        NUMERIC(3,1)
  overview      TEXT
  poster_url    TEXT          -- TMDB /w500
  backdrop_url  TEXT          -- TMDB /w1280

── user_favorites ──────────────────────────────────────────
  id            UUID PK
  user_id       UUID → auth.users(id)
  movie_id      INTEGER → movies(id)
  created_at    TIMESTAMPTZ
  UNIQUE(user_id, movie_id)

── user_ratings ────────────────────────────────────────────
  id            UUID PK
  user_id       UUID → auth.users(id)
  movie_id      INTEGER → movies(id)
  rating        NUMERIC(3,1)  CHECK 0.5..5.0
  UNIQUE(user_id, movie_id)

── profiles ────────────────────────────────────────────────
  id            UUID → auth.users(id)
  full_name     TEXT
  avatar_url    TEXT
```

Row Level Security activé sur toutes les tables.

---

## 🤖 Algorithme de Recommandation — Content-Based Filtering

### Signaux utilisés

| Signal | Facteur | Justification |
|---|---|---|
| **Genres** | ×2 | Signal large, préférence catégorielle |
| **Acteurs** | ×3 | Signal fort, très spécifique à l'utilisateur |
| **Note utilisateur** | bonus ×(rating/5) | Les films mieux notés influencent plus |

### Étapes

```
1. Collecter les films "aimés" :
   liked = favorites ∪ { films notés ≥ 3.5 }

2. Construire le profil de préférence :
   pour chaque film f ∈ liked :
     bonus = (rating[f] / 5.0)  si noté, sinon 1.0
     genre_weight[g] += bonus   pour chaque genre g de f
     actor_weight[a] += bonus   pour chaque acteur a de f

3. Scorer les films non encore vus :
   score(film) = Σ genre_weight[g] × 2.0
               + Σ actor_weight[a] × 3.0

4. Trier par score décroissant → top 15

5. Fallback (0 interaction) : top 15 films par rating DESC
```

```dart
// Extrait de favorites_provider.dart
for (final g in movie.genres) {
  score += (genreWeights[g] ?? 0) * _genreFactor; // ×2
}
for (final a in movie.actors) {
  score += (actorWeights[a] ?? 0) * _actorFactor; // ×3
}
```

---

## 🔧 Dépendances

| Package | Usage |
|---|---|
| `supabase_flutter ^2.5.6` | Auth + DB + Realtime |
| `flutter_riverpod ^2.5.1` | Gestion d'état (StateNotifier, Provider) |
| `shared_preferences ^2.2.3` | Cache local léger |
| `cached_network_image ^3.3.1` | Affiches TMDB avec cache |
| `shimmer ^3.0.0` | Effet skeleton loading |
| `flutter_rating_bar ^4.0.1` | Composant notation ★ |
| `fl_chart ^0.67.0` | Bar charts (genres + acteurs) |

---

## ✅ Grille d'Évaluation

### 1. Architecture & Code `/4`
- ✅ **Riverpod** : `StateNotifierProvider`, `Provider`, `StateProvider`
- ✅ **Structure** : `core/features/models/widgets` respectée
- ✅ **Clean Code** : widgets réutilisables, conventions Dart
- ✅ **Gestion d'erreurs** : try/catch, retry button, optimistic UI (favoris)

### 2. UI / UX `/4`
- ✅ **Material 3** : `ThemeData` centralisé `AppTheme`
- ✅ **Responsive** : `GridView` + `ListView` adaptés
- ✅ **Feedback** : shimmer loading, `SnackBar`, `AnimatedContainer`, `AnimatedSwitcher`
- ✅ **Vraies affiches** : TMDB via `CachedNetworkImage`

### 3. Intégration Technique & Data `/6`
- ✅ **Backend Supabase** : PostgreSQL, RLS, Auth JWT
- ✅ **API REST Supabase** : `.select()`, `.insert()`, `.upsert()`, `.delete()`
- ✅ **Persistance online** : favoris et notes synchronisés sur Supabase
- ✅ **Algorithme IA** : Content-Based Filtering (genres + acteurs + bonus rating)
- ✅ **Visualisation** : 2 BarCharts (genres + acteurs) dans l'onglet Profile
- ✅ **Authentification JWT** : signup / signin via Supabase Auth

### 4. Démo & Maîtrise `/6`
- ✅ README complet avec schéma SQL + algorithme documenté
- ✅ Code commenté dans chaque fichier
- ✅ Flux démo clair (voir ci-dessous)

---

## 📱 Flux Démo

```
Launch → AppGate
  │
  ├─ Session Supabase active? → HomeScreen (4 tabs)
  │
  └─ Non → LoginScreen ←→ RegisterScreen
                │  (Supabase signUp/signIn)
                ▼
           HomeScreen
              ├── Movies  : browse + search (title/genre/actor) + filter genre
              ├── For You : recommandations IA (genres ×2 + actors ×3)
              ├── Favorites : collection synchronisée Supabase
              └── Profile : stats + BarChart genres + BarChart acteurs + Sign Out
                                │
                           MovieDetailScreen
                               ├── Affiche TMDB HD
                               ├── Cast (acteurs scrollable)
                               ├── Overview
                               └── Rating ★ → améliore les recommandations
```

---

## 🚀 Installation

```bash
# 1. Décompresser le projet
cd movierec_express

# 2. Installer les dépendances
flutter pub get

# 3. Lancer
flutter run

# Plateformes supportées : Android · iOS · Web
```

> Les credentials Supabase sont déjà configurés dans `app_constants.dart`.  
> La base de données et les 60 films sont déjà insérés.

---

## 👨‍💻 Auteur

Projet réalisé dans le cadre du module **Développement Mobile Cross-Plateforme** — Flutter  
Évaluation finale : Mini Projet Individuel — *MovieRec Express v2 (Supabase Edition)*
#   m o v i e R e c o m m a n d e d S y s t e m  
 