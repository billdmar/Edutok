# Edutok

**Learn anything, one swipe at a time.**

Edutok is an iOS app that turns any topic into a TikTok-style feed of bite-sized, AI-generated flashcards — wrapped in streaks, achievements, and a leaderboard to make learning genuinely addictive.

![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-18.5%2B-000000?logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0071e3)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Features

- **AI flashcard generation** — Enter any topic and Google Gemini produces an endless feed of concise, accurate facts and questions.
- **Swipeable feed** — A vertical, full-screen card feed inspired by short-form video apps.
- **Rich imagery** — Each card is paired with a relevant photo fetched from Unsplash.
- **Accounts & sync** — Email/password authentication and cloud data sync via Firebase.
- **Gamification** — Daily streaks, XP and levels, unlockable achievements, daily challenges, mystery boxes, and particle-effect celebrations. ([design notes](docs/gamification-design.md))
- **Leaderboard** — Compete with other learners on a global leaderboard.
- **Streak calendar** — Visualize learning consistency over time.
- **Local notifications** — Reminders to keep your streak alive.

## Tech stack

| Area            | Technology                            |
| --------------- | ------------------------------------- |
| UI              | SwiftUI (iOS 18.5+)                   |
| Language        | Swift 5 / Xcode 16                    |
| AI content      | Google Gemini (`gemini-1.5-flash-latest`)    |
| Images          | Unsplash API                          |
| Auth & database | Firebase Auth + Cloud Firestore       |
| Architecture    | MVVM with `ObservableObject` managers |

## Architecture

State is owned by a set of `@MainActor` `ObservableObject` managers, each responsible for one domain, and injected into the SwiftUI view tree:

- **`TopicManager`** — requests flashcards from Gemini and caches generated topics.
- **`ImageManager`** — resolves and caches Unsplash imagery for each card.
- **`FirebaseManager`** — authentication and Firestore reads/writes.
- **`GamificationManager`** — streaks, XP, achievements, challenges, and notifications.

```
Edutok/
├── App.swift                  # App entry point
├── ContentView.swift          # Root view & routing
├── MainView.swift             # Primary flashcard feed
├── FlashcardView.swift        # Individual card UI
├── TopicManager.swift         # Gemini flashcard generation
├── ImageManager.swift         # Unsplash image fetching
├── FirebaseManager.swift      # Auth & Firestore access
├── GamificationManager.swift  # Streaks, XP, achievements
├── *CalendarView.swift        # Streak calendar views
├── LeaderboardView.swift      # Global leaderboard
└── Models.swift               # Core data models
```

## Engineering decisions

A few choices worth calling out:

- **Domain-driven `@MainActor` managers instead of one massive view model.** State is
  split across `TopicManager`, `ImageManager`, `FirebaseManager`, and `GamificationManager`
  — each owns a single domain and is injected into the SwiftUI tree. All are `@MainActor`,
  so published state mutates on the main thread and the UI updates without data races. This
  keeps each concern isolated and made the gamification logic unit-testable on its own.
- **Resilient AI integration.** Flashcards come from Google Gemini (`gemini-1.5-flash-latest`)
  over its REST endpoint, generated in **batches of 15** with a prompt whose depth and topic
  aspect vary by batch number, so an "endless" feed keeps getting deeper instead of repeating.
  Because LLMs wrap JSON in markdown fences and prose, the raw response is sanitized before
  decoding into typed `Codable` structs, the HTTP status is checked, and the request has a
  20-second timeout. Any network or decode failure falls back to deterministic mock cards, so
  the feed is never empty and the app degrades gracefully offline.
- **Gamification modeled as pure, testable logic.** Leveling uses an explicit quadratic XP
  curve — `((n-1)² · 50) + ((n-1) · 50)` XP to reach level _n_ (so L2 = 100, L3 = 300,
  L4 = 600). `UserProgress.addXP` is a pure mutating function that returns whether the user
  leveled up, which drives the celebration animation. Mystery-box rewards use a deliberate
  variable-ratio schedule (50% common / 30% rare / 15% epic / 5% legendary) — a real
  behavioral-design choice, documented in [docs/gamification-design.md](docs/gamification-design.md).
- **Why SwiftUI + Firebase.** SwiftUI for declarative, animation-rich UI (the swipe feed and
  particle effects); Firebase Auth + Firestore for zero-backend auth, cross-device sync, and
  the global leaderboard without standing up a server.

## Testing

Core domain logic is covered by unit tests in `EdutokTests` — the XP/leveling math
(thresholds, level-up detection, progress), topic progress calculation, and the mystery-box
reward ranges — so the gamification rules are verified independently of the UI.

## Getting started

### Prerequisites

- Xcode 16 or later
- An iOS 18.5+ simulator or device
- API keys for Google Gemini and Unsplash
- A Firebase project (iOS app)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/billdmar/Edutok.git
   cd Edutok
   ```

2. **Add your API keys.** Create `Edutok/Secrets.swift` (gitignored — never committed):
   ```swift
   import Foundation

   enum Secrets {
       static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
       static let unsplashAccessKey = "YOUR_UNSPLASH_ACCESS_KEY"
   }
   ```
   - Gemini key: https://aistudio.google.com/app/apikey
   - Unsplash key: https://unsplash.com/oauth/applications

3. **Add Firebase config.** Download your own `GoogleService-Info.plist` from the
   [Firebase Console](https://console.firebase.google.com/) and drop it in `Edutok/`
   (also gitignored).

4. **Open and run**
   ```bash
   open Edutok.xcodeproj
   ```
   Select a simulator and press **⌘R**.

## Security

This project keeps all credentials out of version control:

- API keys live in `Edutok/Secrets.swift`, which is **gitignored**.
- The Firebase `GoogleService-Info.plist` is **gitignored** and supplied per-developer.
- No secrets are committed anywhere in the repository or its history.

## Screenshots

> 📸 Screenshots are being captured in the iOS Simulator and will land here shortly.
> See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the capture plan.

<!-- Uncomment once the PNGs are committed to docs/.
| Flashcard feed | Topic generation | Gamification |
| :--: | :--: | :--: |
| ![Feed](docs/feed.png) | ![Generate](docs/generate.png) | ![Gamification](docs/gamification.png) |

| Streak calendar | Leaderboard |
| :--: | :--: |
| ![Streak](docs/streak.png) | ![Leaderboard](docs/leaderboard.png) |
-->

## Roadmap

- [x] AI flashcard generation, swipe feed, gamification, global leaderboard
- [ ] Study groups & social features
- [ ] Skill trees / topic specializations
- [ ] On-device personalization of card difficulty

See the [gamification design notes](docs/gamification-design.md) for the full plan.

## License

Released under the [MIT License](LICENSE).
