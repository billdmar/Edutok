/// AnimationConstants.swift
///
/// Named durations for the app's transient animations / auto-dismiss timers, so the same
/// value isn't repeated as a magic number across views and the manager (and so the timing
/// can be tuned in one place).
import Foundation

enum AnimationConstants {
    /// How long a reward overlay (level-up, achievement toast, mystery-box reveal, XP gain)
    /// stays on screen before auto-hiding.
    static let rewardDisplay: TimeInterval = 3.0

    /// Short delay used to reset card/transition state after a swipe animation settles.
    static let transitionReset: TimeInterval = 0.3

    /// Lifetime of a celebratory particle burst.
    static let particleBurst: TimeInterval = 4.0
}
