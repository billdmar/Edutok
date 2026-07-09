/// Tips.swift
///
/// TipKit tip definitions for contextual onboarding. Tips appear once per user
/// and respect the system's display frequency to avoid overwhelming new users.
import SwiftUI
import TipKit

struct SwipeTip: Tip {
    var title: Text { Text("Swipe to Navigate") }
    var message: Text? { Text("Swipe up for the next card, down for previous.") }
    var image: Image? { Image(systemName: "hand.draw") }
}

struct FlipTip: Tip {
    var title: Text { Text("Tap to Reveal") }
    var message: Text? { Text("Tap the card to flip it and see the answer.") }
    var image: Image? { Image(systemName: "rectangle.portrait.rotate") }
}

struct GradeTip: Tip {
    static let cardFlipped = Tips.Event(id: "cardFlipped")

    var title: Text { Text("Rate Your Recall") }
    var message: Text? { Text("'Got it' earns XP. 'Again' brings the card back sooner.") }
    var image: Image? { Image(systemName: "hand.thumbsup") }

    var rules: [Rule] {
        #Rule(Self.cardFlipped) { $0.donations.count >= 1 }
    }
}

struct BookmarkTip: Tip {
    static let cardsViewed = Tips.Event(id: "cardsViewed")

    var title: Text { Text("Save for Later") }
    var message: Text? { Text("Tap the bookmark icon to save cards you want to revisit.") }
    var image: Image? { Image(systemName: "bookmark") }

    var rules: [Rule] {
        #Rule(Self.cardsViewed) { $0.donations.count >= 3 }
    }
}

struct StreakTip: Tip {
    static let sessionCompleted = Tips.Event(id: "sessionCompleted")

    var title: Text { Text("Build Your Streak") }
    var message: Text? { Text("Come back daily to build your streak and earn bonus XP.") }
    var image: Image? { Image(systemName: "flame") }

    var rules: [Rule] {
        #Rule(Self.sessionCompleted) { $0.donations.count >= 1 }
    }
}
