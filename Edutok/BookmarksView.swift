/// BookmarksView.swift
///
/// Surfaces the cards a user bookmarked (swipe-left in the feed). Bookmarking already
/// persisted to `UserDefaults` via `TopicManager.toggleBookmark`, but there was no way
/// to review saved cards — this view closes that loop. Tap a card to flip it; remove a
/// bookmark inline.
import SwiftUI

/// A flashcard plus the context needed to locate and mutate it within `TopicManager`
/// (topic id, title, and index). Shared by the bookmarks and review screens.
struct CardLocator: Identifiable {
    var id: UUID { card.id }
    let card: Flashcard
    let topicId: UUID
    let topicTitle: String
    let cardIndex: Int
}

struct BookmarksView: View {
    @EnvironmentObject var topicManager: TopicManager
    @Environment(\.dismiss) private var dismiss

    private var cards: [CardLocator] { topicManager.bookmarkedCards }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                if cards.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(cards) { item in
                                BookmarkCardRow(item: item) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        topicManager.toggleBookmark(topicId: item.topicId,
                                                                    cardIndex: item.cardIndex)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Saved Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 52))
                .foregroundColor(Theme.textSecondary)
            Text("No saved cards yet")
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.textPrimary)
            Text("Swipe left on any card while learning to save it here for later review.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A single bookmarked card; taps flip between question and answer.
private struct BookmarkCardRow: View {
    let item: CardLocator
    let onRemove: () -> Void
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.topicTitle.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.accent)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.accent)
                        .frame(width: 44, height: 44) // ≥44pt tap target
                }
                .accessibilityLabel("Remove bookmark")
            }

            Text(showAnswer ? item.card.answer : item.card.question)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(showAnswer ? "Tap to see question" : "Tap to reveal answer")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { showAnswer.toggle() }
        }
        .accessibilityHint("Double-tap to flip the card")
    }
}
