/// ReviewView.swift
///
/// Spaced-repetition review session. Surfaces understood cards that are "due" per
/// `ReviewScheduler`, lets the user flip each to self-test, and marks them reviewed —
/// which defers them to the next (longer) interval. The due set is snapshotted on appear
/// so marking a card reviewed doesn't make it vanish mid-session.
import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var topicManager: TopicManager
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [CardLocator] = []
    @State private var reviewedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                if queue.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            header
                            ForEach(queue) { item in
                                ReviewCardRow(
                                    item: item,
                                    isReviewed: reviewedIDs.contains(item.card.id)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        topicManager.markReviewed(topicId: item.topicId,
                                                                  cardIndex: item.cardIndex)
                                        reviewedIDs.insert(item.card.id)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        // Snapshot the due set once so reviewing a card doesn't remove it mid-session.
        .onAppear { if queue.isEmpty { queue = topicManager.dueReviewCards } }
    }

    private var header: some View {
        let remaining = queue.count - reviewedIDs.count
        return VStack(spacing: 6) {
            Text(remaining == 0 ? "All caught up! 🎉" : "\(remaining) card\(remaining == 1 ? "" : "s") to review")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("Reviewing strengthens recall on a spaced schedule.")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 52))
                .foregroundColor(Theme.textSecondary)
            Text("Nothing to review")
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.textPrimary)
            Text("Mark cards as understood while learning. They'll resurface here on a spaced schedule so you remember them long-term.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A single review card: tap to flip, then mark reviewed.
private struct ReviewCardRow: View {
    let item: CardLocator
    let isReviewed: Bool
    let onMarkReviewed: () -> Void
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.topicTitle.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.accent)
                Spacer()
                if isReviewed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Reviewed")
                }
            }

            Text(showAnswer ? item.card.answer : item.card.question)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if showAnswer {
                Button(action: onMarkReviewed) {
                    Label(isReviewed ? "Reviewed" : "Got it — mark reviewed",
                          systemImage: isReviewed ? "checkmark" : "brain.head.profile")
                }
                .buttonStyle(ChipButtonStyle())
                .disabled(isReviewed)
            } else {
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(isReviewed ? 0.04 : 0.08))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
        .opacity(isReviewed ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { showAnswer.toggle() }
        }
        .accessibilityHint("Double-tap to flip the card")
    }
}
