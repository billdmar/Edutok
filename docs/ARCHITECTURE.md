# Edutok Architecture

Edutok is a SwiftUI iOS app (iOS 18.5+) that turns any topic into a TikTok-style
feed of AI-generated flashcards, wrapped in a gamification layer (XP, streaks,
achievements, daily challenges, mystery boxes) and a Firebase-backed leaderboard.

This document describes how the pieces fit together, grounded in the actual source
under `Edutok/`. Where something is a stub, fallback, or known limitation, it is
called out explicitly.

## Design at a glance

State is split across four `@MainActor` `ObservableObject` "manager" types, each
owning a single domain. They are created once in the app entry point and injected
into the SwiftUI view tree (either as `environmentObject`s or accessed via a shared
singleton). Because every manager is `@MainActor`, published state mutates on the
main thread and the UI updates without data races.

| Manager | Lifetime | Responsibility |
| --- | --- | --- |
| `TopicManager` | `@StateObject` in `FlashTokApp`, injected as `environmentObject` | Generates flashcards via Gemini; persists topics to `UserDefaults` |
| `GamificationManager` | `@StateObject` in `FlashTokApp`, injected as `environmentObject` | XP/levels, daily challenges, mystery boxes, achievements, notifications |
| `FirebaseManager` | `.shared` singleton (`@StateObject` references) | Auth + Firestore profile, daily stats, streaks, leaderboard |
| `ImageManager` | `.shared` singleton | Resolves + caches Unsplash image URLs per card |

## Data-flow diagram

```
                         ┌──────────────────────────────────────────┐
                         │  FlashTokApp (@main, App.swift)            │
                         │  • AppDelegate → FirebaseApp.configure()   │
                         │  • owns TopicManager, GamificationManager  │
                         │  • references FirebaseManager.shared       │
                         │  • anonymous sign-in on launch             │
                         └───────────────────┬──────────────────────┘
                                             │ environmentObjects
                                             ▼
                         ┌──────────────────────────────────────────┐
                         │  ContentView (root router)                 │
                         │  AppSection: .main/.flashcards/            │
                         │              .leaderboard/.calendar        │
                         │  + floating bottom nav bar                 │
                         └──┬─────────────┬──────────────┬───────────┘
                            │             │              │
              currentTopic==nil      currentTopic!=nil   │
                            ▼             ▼              ▼
                   ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐
                   │  MainView   │  │FlashcardView│  │ LeaderboardWrapper│
                   │ topic entry │  │ swipe feed  │  │ StandaloneCalendar│
                   └──────┬──────┘  └──────┬──────┘  └────────┬─────────┘
                          │ generateFlashcards    │ swipes / flips     │ fetchDailyLeaderboard
                          ▼                        ▼                    ▼
   ┌───────────────┐   ┌──────────────────────────────────────┐   ┌───────────────────┐
   │  ImageManager  │◄──┤            TopicManager               │   │   FirebaseManager  │
   │ (Unsplash +    │   │  fetchFlashcardsFromGemini()          │   │  Auth + Firestore  │
   │  Gemini kw)    │   │  → mock fallback on failure           │   │  trackCardFlipped  │
   └──────┬─────────┘   │  persists Topics → UserDefaults        │   │  trackTopicExplored│
          │             └───────────────┬──────────────────────┘   │  updateStreak      │
          │ HTTPS                        │ NotificationCenter         │  daily leaderboard │
          ▼                              ▼ "TopicExplored"            └─────────┬──────────┘
   api.unsplash.com          ┌──────────────────────────┐                      │ HTTPS
   generativelanguage        │   GamificationManager     │                      ▼
   .googleapis.com           │ XP/levels, challenges,    │              Cloud Firestore
   (Gemini 1.5 Flash)        │ mystery boxes, achievements│             (users, leaderboards)
                             │ persists → UserDefaults    │
                             │ UNUserNotificationCenter   │
                             └──────────────────────────┘
```

## App entry & structure

`App.swift` defines `@main struct FlashTokApp` (the product/scheme is named
**Edutok**; the SwiftUI `App` type retains the project's original "FlashTok" name).
It:

- Registers an `AppDelegate` via `@UIApplicationDelegateAdaptor`, whose
  `didFinishLaunchingWithOptions` calls `FirebaseApp.configure()`.
- Creates `TopicManager`, `GamificationManager`, and references
  `FirebaseManager.shared` as `@StateObject`s.
- Injects `topicManager` and `gamificationManager` as `environmentObject`s and
  forces `.preferredColorScheme(.dark)`.
- On appear: schedules a study-reminder local notification and, if not already
  authenticated, kicks off `FirebaseManager.signInAnonymously()`.

`ContentView` is the root router. It holds `currentSection: AppSection`
(`.main`, `.flashcards`, `.leaderboard`, `.calendar`) and renders the matching
screen, plus a floating bottom navigation bar (Leaderboard / Learn / Calendar)
shown only on the non-study sections. Selecting a topic (`topicManager.currentTopic
!= nil`) auto-switches to the flashcard feed via `onChange`.

`Color`/`View` extensions in `ContentView.swift` define the app's purple/pink/blue
palette (`flashTokPurple`, `flashTokPink`, `flashTokBlue`) and a `flashTokStyle()`
gradient modifier.

## The swipeable card feed

`FlashcardView` is the TikTok-style feed. Key mechanics (verified in the source):

- It renders an **infinite scroll stack** (`infiniteCards`) of `ZStack`ed cards,
  drawing the previous / current / next cards (relative index within ±2) for smooth
  transitions, with TikTok-style offset/scale transitions per card.
- A `DragGesture` on the current card maps gestures to actions:
  - **Swipe up** → `nextCard()`
  - **Swipe down** → `previousCard()`
  - **Swipe right** (≥ 2× threshold) → `markAsUnderstood()` then `nextCard()`
  - **Swipe left** (≥ 2× threshold) → `toggleBookmark()` (bounces back to center)
  - Velocity (`predictedEndTranslation`) is also considered for up/down.
  - `UIImpactFeedbackGenerator` fires haptics on each committed swipe.
- Tapping a card flips it between question and answer (`showAnswer`,
  `cardRotation`).
- The feed grows endlessly: when nearing the end of the deck it calls
  `topicManager.generateMoreFacts(for:)` to append another batch.
- Side effects on interaction:
  - First flip of a card → `FirebaseManager.shared.trackCardFlipped()`.
  - Marking understood → `TopicManager.markCardAsUnderstood(...)` and
    `GamificationManager.awardXP(.perfectCard)`; completion also calls
    `awardXPForCardCompletion(wasCorrect:isFirstTry:timeToAnswer:)`.
  - XP is awarded at most once per card (`cardXPAwarded: Set<UUID>`).

## Gemini-powered flashcard generation

`TopicManager` (`@MainActor`) owns the user's topics and is the single source of
truth for the active topic. It persists `savedTopics` to `UserDefaults` (key
`"SavedTopics"`) as JSON.

Generation flow (`fetchFlashcardsFromGemini(topic:batchNumber:)`):

1. Builds a `POST` to
   `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=<Secrets.geminiAPIKey>`.
2. The prompt (`createEnhancedFactsPrompt`) asks for **exactly 15 cards** as JSON,
   and varies *focus aspect* and *depth level* by `batchNumber` so an "endless"
   feed keeps getting deeper instead of repeating
   (`getEnhancedTopicAspect` / `getDepthLevel`).
3. `generationConfig`: `temperature 0.7`, `maxOutputTokens 3000`, `topP 0.8`;
   request `timeoutInterval` 20s.
4. The response is decoded into a nested `GeminiResponse` struct; the first
   candidate's text is sanitized by `cleanJSONResponse` (strips ```` ```json ````
   fences, normalizes smart quotes, narrows to the outer `[ ... ]` array) and then
   decoded into typed `Flashcard`s. The card `type` string is normalized into the
   `FlashcardType` enum (`definition` / `question` / `truefalse` / `fillblank`),
   defaulting to `.question`.

**Resilience / fallback:** any failure path — bad URL, non-200 HTTP, missing
candidates, non-UTF-8 text, or decode error — throws `APIError.invalidResponse`,
and the caller falls back to `createEnhancedMockFlashcards(for:)`, a fixed set of
15 topic-templated cards. The feed is therefore **never empty** and the app degrades
gracefully offline. Each generated/mock card is then assigned an image URL via
`ImageManager` before the topic is saved and activated.

`generateMoreFacts(for:)` advances the batch number (`flashcards.count / 15 + 2`)
and appends the next batch, with the same fallback behavior.

> **Note:** `Secrets.geminiAPIKey` / `Secrets.unsplashAccessKey` live in
> `Edutok/Secrets.swift`, which is **gitignored** and supplied per developer (CI
> writes a non-functional stub so the project compiles — see below).

## Image fetching (Unsplash + Gemini keywords)

`ImageManager` (`.shared`, `@MainActor`) resolves a relevant image URL per card and
caches results in two bounded `NSCache`s (`countLimit = 500` each):

1. `generateImageKeywords(for:topic:)` asks Gemini (same model endpoint) to produce
   3–4 specific visual search keywords for the card. On any failure it returns a
   fallback string derived from the topic + question text — it always returns a
   usable value.
2. Those keywords are queried against the Unsplash search API
   (`https://api.unsplash.com/search/photos?...&client_id=<Secrets.unsplashAccessKey>`,
   landscape, `per_page=5`) and one of the results is chosen for variety
   (`generateDiverseImageForFlashcard(question:topic:variation:)`).
3. Non-200 responses (401 invalid key, 403 rate-limited, etc.) and decode failures
   return `nil`, in which case the card simply shows its gradient placeholder.

## Firebase Auth + Firestore: data model & sync

`FirebaseManager` (`.shared`, `@MainActor`) is the single entry point for auth and
persistence. It configures Firebase once (guarding against double-`configure`),
installs an auth state listener, and on sign-in loads-or-creates the user's profile.

**Auth.** Supports anonymous sign-in (used automatically on launch),
email/password sign-in & sign-up, and phone-number verification
(`signInWithPhone` / `verifyPhoneCode`). Phone auth requires extra Firebase Console
setup and "may not work in simulator" (noted in code).

**User document (`users/{uid}`)** — mirrors `AppUser` (`FirebaseModels.swift`):

| Field | Type | Notes |
| --- | --- | --- |
| `username` | String | Random `AdjectiveNounNNN` by default; capped at 30 chars |
| `totalCardsFlipped` | Int | |
| `totalTopicsExplored` | Int | |
| `currentStreak` / `longestStreak` | Int | |
| `lastActiveDate` / `joinDate` | Timestamp | |
| `dailyStats` | Array | per-day `DailyStat`: `date`, `cardsFlipped`, `topicsExplored`, `achievements[]` |

**Activity tracking.** `trackCardFlipped()` / `trackTopicExplored()` /
`trackAchievement(_:)` bump totals, update (or create) today's `DailyStat`, refresh
the streak (`updateStreak`), persist the user, and update the relevant leaderboard.
`updateStreak` increments the current streak when there was activity today and
either yesterday or a zero starting streak, tracks `longestStreak`, and resets to 0
on an inactive day.

**Leaderboards.** Two per-day collections, `daily_cards_leaderboard` and
`daily_topics_leaderboard`, keyed `"{yyyy-MM-dd}_{uid}"`. `fetchDailyLeaderboard`
queries the top 50 by descending value, filters to today's documents by the
`documentID` date prefix, flags the current user, and assigns 1-based ranks.

**Resilience.** Firestore writes are best-effort (`try?`) so transient backend
failures never crash the app; if a profile can't be loaded, an in-memory fallback
`AppUser` is created so the app remains usable offline.

## Gamification system

`GamificationManager` (`@MainActor`) drives all reward mechanics; the value types
live in `GamificationModels.swift` and `Models.swift`. Progress persists to
`UserDefaults`; key milestones mirror to Firebase via `FirebaseManager`.

- **XP & levels.** `UserProgress` tracks `totalXP` as the single source of truth and
  recomputes `currentLevel` from it. The level curve is quadratic:
  `levelToXPRequired(n) = ((n-1)² · 50) + ((n-1) · 50)` — so **L2 = 100, L3 = 300,
  L4 = 600**. `addXP(_:)` is a pure mutating function returning whether the gain
  produced a level-up (used to trigger the level-up animation). XP amounts come from
  the `XPReward` enum (e.g. `cardCompleted = 10`, `correctAnswer = 15`,
  `perfectCard = 25`, `topicCompleted = 100`, `streakBonus = 20`).
- **Daily challenges.** Three challenges generated per day (Card Master, Perfect
  Score, Topic Explorer), each with a target, XP reward, and an `expiresAt` set to
  the start of tomorrow. Progress is advanced via `updateChallengeProgress(type:)`;
  topic-exploration progress arrives over `NotificationCenter` (`"TopicExplored"`,
  posted by `TopicManager`) — a deliberately loose coupling between the two managers.
- **Mystery boxes.** 3–5 boxes generated per session with a variable-ratio rarity
  schedule — **50% common / 30% rare / 15% epic / 5% legendary** (see
  `randomRarity()` and `BoxRarity.xpRange`). Opening a box awards XP in its rarity
  range. This is a documented behavioral-design choice (see
  [gamification-design.md](gamification-design.md)).
- **Achievements.** Two systems coexist: the original `Achievement` enum (First
  Steps, Scholar, Speed Demon, Night Owl, Explorer, Perfectionist, Dedicated,
  Unstoppable — each with title/description/emoji/XP) and the newer
  `EnhancedAchievement` value type with rarity + category (`AchievementRarity`,
  `AchievementCategory`), checked by `checkEnhancedAchievements()`.
- **Celebrations & notifications.** Level-ups, achievements, and box openings emit
  particle effects (`ParticleEffectsView`) and toast/animation state. Local
  notifications (`UNUserNotificationCenter`) cover study reminders, encouragement,
  and streak warnings.
- **Streaks.** Streak counting for the *profile/leaderboard* lives in
  `FirebaseManager.updateStreak`; the streak calendar UI
  (`StreakCalendarView` / `StandaloneCalendarView`) visualizes `DailyStat` activity
  with `ActivityLevel` heat-map shading.

## Persistence summary

| Data | Store | Key / collection |
| --- | --- | --- |
| Saved topics & flashcards | `UserDefaults` (JSON) | `SavedTopics` |
| XP / level progress | `UserDefaults` (JSON) | `UserProgress` |
| Daily challenges | `UserDefaults` (JSON) | `DailyChallenges` |
| Mystery boxes | `UserDefaults` (JSON) | `MysteryBoxes` |
| Enhanced achievements | `UserDefaults` (JSON) | `EnhancedAchievements` |
| Image URL cache | in-memory `NSCache` (bounded) | — |
| User profile, daily stats | Cloud Firestore | `users/{uid}` |
| Leaderboards | Cloud Firestore | `daily_cards_leaderboard`, `daily_topics_leaderboard` |

## Secrets, configuration & CI

- **`Edutok/Secrets.swift`** (gitignored) must define
  `enum Secrets { static let geminiAPIKey; static let unsplashAccessKey }`.
  The source references these directly; without the file the project will not
  compile.
- **`Edutok/GoogleService-Info.plist`** (gitignored) holds the Firebase client
  config consumed at `FirebaseApp.configure()`.
- Dependencies are managed via **Swift Package Manager** in the `.pbxproj`
  (Firebase iOS SDK: `FirebaseAuth`, `FirebaseCore`, `FirebaseFirestore`). There is
  no Podfile or `Package.swift`.
- **CI** (`.github/workflows/ci.yml`) runs on `macos-15`. Because both files above
  are gitignored, CI writes a **non-functional stub `Secrets.swift`** and a
  **valid placeholder `GoogleService-Info.plist`** before resolving packages, so the
  project compiles and `FirebaseApp.configure()` succeeds. The stub keys are not
  valid, so no real backend is contacted during a build/unit-test run.

## Testing

Unit tests in `EdutokTests` (Swift Testing framework) cover the **pure domain
logic** with no Firebase/network dependency: the XP/leveling math (thresholds,
level-up detection, in-level progress), topic progress percentage, and reward
ranges. CI runs only `-only-testing:EdutokTests`. `EdutokUITests` exists as the
standard UI-test target but is not exercised in CI.

## Known stubs & limitations

- The SwiftUI `App` type is still named `FlashTokApp` (legacy "FlashTok" name); the
  product/scheme/bundle is **Edutok**.
- `MainView` has a "Refresh" button on Trending Topics and an inline
  "search suggestions" block that are placeholders / no-ops in the current source.
- Phone auth is wired but requires Firebase Console setup and may not work in the
  simulator.
- Generated images depend on a valid Unsplash key; without one (or on rate-limit)
  cards fall back to gradient placeholders.
