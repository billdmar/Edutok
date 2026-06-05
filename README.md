# Edutok

**Learn anything, one swipe at a time.**

Edutok is an iOS app that turns any topic into a TikTok-style feed of bite-sized, AI-generated flashcards — wrapped in streaks, achievements, and a leaderboard to make learning genuinely addictive.

![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)
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
| UI              | SwiftUI (iOS 17+)                     |
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

## Getting started

### Prerequisites

- Xcode 16 or later
- An iOS 17+ simulator or device
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

| Flashcard feed | Topic generation | Gamification |
| :--: | :--: | :--: |
| ![Feed](docs/feed.png) | ![Generate](docs/generate.png) | ![Gamification](docs/gamification.png) |

| Streak calendar | Leaderboard |
| :--: | :--: |
| ![Streak](docs/streak.png) | ![Leaderboard](docs/leaderboard.png) |

<!-- Capture in the iOS Simulator (File ▸ Save Screen / ⌘S), then drop the PNGs into
     docs/ using the exact filenames above. See docs/SCREENSHOTS.md for the guide. -->

## License

Released under the [MIT License](LICENSE).
