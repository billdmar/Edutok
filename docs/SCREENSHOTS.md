# Screenshots

The README's Screenshots section and the slots below expect five PNGs in this
`docs/` folder. Until you add them they render as broken images — that's expected.

| Slot | What to show |
| --- | --- |
| ![Flashcard feed](feed.png) | `feed.png` — the swipeable flashcard feed with a generated card + its image |
| ![Topic entry](topic.png) | `topic.png` — the topic-entry / "Start Learning" screen |
| ![Gamification](gamification.png) | `gamification.png` — XP/level, achievements, or a mystery-box / celebration moment |
| ![Streak calendar](streak.png) | `streak.png` — the streak calendar view |
| ![Leaderboard](leaderboard.png) | `leaderboard.png` — the global leaderboard |

## How to capture

1. **Add an iOS simulator** (one time): Xcode ▸ **Settings… ▸ Components** (older
   Xcode: **Platforms**) ▸ download an **iOS** simulator runtime.
2. **Add your real keys** (so the feed shows real content). Edutok calls Google
   Gemini + Unsplash and uses Firebase, so for compelling screenshots:
   - Create `Edutok/Secrets.swift` (gitignored — never commit it):
     ```swift
     import Foundation

     enum Secrets {
         static let geminiAPIKey = "YOUR_REAL_GEMINI_KEY"
         static let unsplashAccessKey = "YOUR_REAL_UNSPLASH_KEY"
     }
     ```
   - Drop your real `GoogleService-Info.plist` (from the Firebase console) into
     `Edutok/` (also gitignored).

   > Without these the app builds but the feed stays empty and the leaderboard
   > won't populate — so the keys are what make the screenshots compelling.
3. **Run the app**: open `Edutok.xcodeproj`, pick an **iPhone 16 Pro** simulator,
   press **⌘R**. Sign in, enter a topic (e.g. "Roman Empire"), and let the AI
   generate the feed.
4. **Capture each screen**: focus the simulator and press **⌘S**
   (File ▸ Save Screen). macOS saves a device-framed PNG to your **Desktop**.
5. **Rename and drop them into `docs/`**, then push:
   ```bash
   # rename captured PNGs to the names in the table above, then:
   cp ~/Desktop/{feed,topic,gamification,streak,leaderboard}.png docs/
   git add docs/*.png
   git commit -m "docs: add app screenshots"
   git push
   ```
   The README tables and the slots above render them automatically.

> Tip: capture all five in the same simulator/orientation so the table rows line up.
