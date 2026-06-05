# Capturing screenshots for the README

The README's Screenshots tables expect five PNGs in this `docs/` folder:
`feed.png`, `generate.png`, `gamification.png`, `streak.png`, `leaderboard.png`.

## 1. Install an iOS simulator (one time)
Xcode ▸ **Settings… ▸ Components** (older Xcode: **Platforms**) ▸ download an
**iOS** simulator runtime (~7 GB).

## 2. Add your real keys (required for live content)
Edutok calls Google Gemini + Unsplash and uses Firebase, so for screenshots that
show real AI-generated flashcards you need:

1. Create `Edutok/Secrets.swift` (gitignored — never commit it):
   ```swift
   enum Secrets {
       static let geminiAPIKey = "YOUR_REAL_GEMINI_KEY"
       static let unsplashAccessKey = "YOUR_REAL_UNSPLASH_KEY"
   }
   ```
2. Drop your real `GoogleService-Info.plist` (from the Firebase console) into
   `Edutok/` (also gitignored).

> Without these, the app builds but the feed stays empty and the leaderboard
> won't populate — so the keys are what make the screenshots compelling.

## 3. Run the app
1. Open `Edutok.xcodeproj`, pick an **iPhone 16 Pro** simulator, press **⌘R**.
2. Sign in / create an account, enter a topic (e.g. "Roman Empire") and let the
   AI generate the flashcard feed.

## 4. Capture each screen
Focus the simulator and press **⌘S** (File ▸ Save Screen) for a device-framed PNG.

| Filename | What to show |
| --- | --- |
| `feed.png` | The swipeable flashcard feed with a generated card + its image |
| `generate.png` | The topic-entry / generation screen |
| `gamification.png` | XP/level, achievements, or a mystery-box / celebration moment |
| `streak.png` | The streak calendar view |
| `leaderboard.png` | The global leaderboard |

## 5. Drop them in and push
```bash
# rename captured PNGs to the names above, then:
cp ~/Desktop/{feed,generate,gamification,streak,leaderboard}.png docs/
git add docs/*.png
git commit -m "docs: add app screenshots"
git push
```
The README tables render them automatically.

> Tip: capture all five in the same simulator/orientation so the table rows line up.
