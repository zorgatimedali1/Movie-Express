# 🎬 MovieRec Express — v3

> Application Flutter de recommandation de films  
> Supabase · PostgreSQL · Riverpod · CineBot AI (Groq)  
> Projet Flutter Cross-Platform — Polytechnique 2026

---

# 📋 Présentation

**MovieRec Express** est une application Flutter intelligente de recommandation de films.

L’application utilise :

- **Supabase** pour l’authentification et la base PostgreSQL
- **Riverpod** pour la gestion d’état
- **TMDB** pour les affiches réelles
- **Groq + Llama 3.1** pour le chatbot IA CineBot
- Un système de recommandation **Content-Based Filtering**

---

# 🤖 CineBot — Assistant IA

CineBot permet de rechercher des films par conversation naturelle :

| Exemple | Résultat |
|---|---|
| "Je veux un thriller" | Suggestions thriller |
| "Un film triste" | Films émotionnels |
| "Film avec DiCaprio" | Recherche par acteur |
| "comdie romantike" | Tolérance aux fautes |

---

## ⚙️ Fonctionnement de CineBot

```text
Utilisateur → ChatScreen
        │
        ▼
chatProvider récupère les films
        │
        ▼
Contexte envoyé à Groq API
        │
        ▼
Llama 3.1 analyse :
- message
- catalogue
- historique
        │
        ▼
Réponse IA avec recommandations
```

---

# 🏗️ Architecture du Projet

```text
lib/
│
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
│
├── chat/
│   ├── models/
│   ├── providers/
│   └── screens/
│
├── features/
│   ├── auth/
│   └── movies/
│
└── main.dart
```

---

# 📁 Structure Complète

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── services/
│   │   └── ai_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── supabase_service.dart
│
├── chat/
│   ├── models/
│   │   └── chat_message.dart
│   ├── providers/
│   │   └── chat_provider.dart
│   └── screens/
│       └── chat_screen.dart
│
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   └── movies/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── widgets/
│
└── main.dart
```

---

# 🗄️ Base de Données Supabase

```sql
movies
- id
- title
- genres
- actors
- director
- year
- rating
- overview
- poster_url
- backdrop_url

user_favorites
- user_id
- movie_id

user_ratings
- user_id
- movie_id
- rating

profiles
- full_name
- avatar_url
```

---

# 🤖 Algorithme de Recommandation

## Signaux utilisés

| Signal | Poids |
|---|---|
| Genres | ×2 |
| Acteurs | ×3 |
| Note utilisateur | bonus |

---

## Étapes

```text
1. Collecter les films aimés
2. Construire le profil utilisateur
3. Calculer un score pour chaque film
4. Trier les résultats
5. Retourner le Top 15
```

---

## Exemple de calcul

```dart
for (final g in movie.genres) {
  score += (genreWeights[g] ?? 0) * 2;
}

for (final a in movie.actors) {
  score += (actorWeights[a] ?? 0) * 3;
}
```

---

# 🔧 Dépendances Principales

| Package | Usage |
|---|---|
| supabase_flutter | Auth + PostgreSQL |
| flutter_riverpod | State Management |
| http | Appels API Groq |
| shared_preferences | Cache local |
| cached_network_image | Cache images |
| shimmer | Skeleton loading |
| flutter_rating_bar | Notes ★ |
| fl_chart | Graphiques |

---

# 📱 Fonctionnalités

- Authentification Supabase
- Recherche films
- Filtres par genre
- Système favoris
- Notes utilisateurs
- Recommandations IA
- Chatbot CineBot
- Skeleton loading
- Bar charts statistiques
- Responsive UI
- Material 3

---

# 📱 Flux de l’Application

```text
Launch
  │
  ├── Session active ?
  │       │
  │       ├── Oui → HomeScreen
  │       └── Non → Login/Register
  │
  ▼
HomeScreen
  ├── Movies
  ├── For You
  ├── Favorites
  └── Profile

MovieDetailScreen
  ├── Poster HD
  ├── Cast
  ├── Overview
  └── Rating

ChatScreen
  ├── CineBot
  ├── Suggestions rapides
  └── Conversation IA
```

---

# 🚀 Installation

## ✅ Prérequis

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Compte Supabase
- Clé API Groq

---

## 📦 Installer les dépendances

```bash
flutter pub get
```

---

## 🔑 Configurer les clés API

Modifier :

```text
lib/core/constants/app_constants.dart
```

```dart
static const supabaseUrl = 'YOUR_SUPABASE_URL';

static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

static const groqApiKey = 'YOUR_GROQ_API_KEY';
```

---

## ▶️ Lancer l’application

```bash
flutter run
```

---

# 📡 APIs utilisées

| API | Usage |
|---|---|
| Supabase | Auth + Database |
| TMDB | Posters films |
| Groq API | CineBot AI |

---

# 🎯 Points Techniques Clés

## Supabase Auth

- JWT automatique
- Session persistante
- Login/Register sécurisés

---

## Row Level Security

Toutes les tables utilisent :

```sql
RLS ENABLED
```

Chaque utilisateur accède uniquement à ses données.

---

## CineBot

Le chatbot utilise :

```text
Groq API
Model:
llama-3.1-8b-instant
```

---

# 📊 Évaluation Technique

| Critère | État |
|---|---|
| Architecture Flutter | ✅ |
| Riverpod | ✅ |
| UI/UX Material 3 | ✅ |
| Supabase | ✅ |
| Algorithme IA | ✅ |
| Auth JWT | ✅ |
| README complet | ✅ |

---

# 👨‍💻 Auteur

**MovieRec Express v3**  
Projet Flutter Cross-Platform — Polytechnique 2026
