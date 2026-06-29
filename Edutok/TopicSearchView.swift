/// TopicSearchView.swift
///
/// Searchable history of every saved topic. Filtering mirrors the home screen's
/// case-insensitive match; tapping a result resumes that topic (sets
/// `TopicManager.currentTopic`, which routes the app to the flashcard feed) and dismisses.
import SwiftUI

struct TopicSearchView: View {
    @EnvironmentObject var topicManager: TopicManager
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    /// Saved topics matching the query (case-insensitive on title), newest first.
    private var results: [Topic] {
        let sorted = topicManager.savedTopics.sorted { $0.createdAt > $1.createdAt }
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                if topicManager.savedTopics.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { topic in
                                TopicHistoryRow(topic: topic) {
                                    topicManager.currentTopic = topic
                                    dismiss()
                                }
                            }
                            if results.isEmpty {
                                Text("No topics match \"\(query)\"")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.top, 40)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Your Topics")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search your topics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52))
                .foregroundColor(Theme.textSecondary)
            Text("No topics yet")
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.textPrimary)
            Text("Topics you learn will appear here so you can search and resume them anytime.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One topic in the history list: title, card count, progress bar, resume on tap.
private struct TopicHistoryRow: View {
    let topic: Topic
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(topic.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(topic.progressPercentage)%")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Theme.accent)
                }

                Text("\(topic.flashcards.count) cards")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(height: 4)
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.pink, Theme.purple],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(topic.progressPercentage) / 100,
                                   height: 4)
                    }
                }
                .frame(height: 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title), \(topic.progressPercentage) percent complete, \(topic.flashcards.count) cards")
        .accessibilityHint("Double-tap to resume")
    }
}
