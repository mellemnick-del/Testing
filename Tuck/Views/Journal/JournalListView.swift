import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var search = ""
    @State private var isWriting = false

    private var filtered: [JournalEntry] {
        guard !search.isEmpty else { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(search) || $0.body.localizedCaseInsensitiveContains(search)
        }
    }

    /// Entries grouped by month, newest month first.
    private var sections: [(month: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) {
            calendar.dateInterval(of: .month, for: $0.createdAt)?.start ?? $0.createdAt
        }
        return grouped
            .map { (month: $0.key, entries: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        symbol: "book.closed",
                        title: "Your journal",
                        message: "A few lines a day adds up. Tap the pencil to start."
                    )
                } else {
                    List {
                        ForEach(sections, id: \.month) { section in
                            Section(section.month.formatted(.dateTime.month(.wide).year())) {
                                ForEach(section.entries) { entry in
                                    NavigationLink {
                                        JournalDetailView(entry: entry)
                                    } label: {
                                        JournalRow(entry: entry)
                                    }
                                    .listRowBackground(Theme.card)
                                }
                                .onDelete { offsets in
                                    for index in offsets { context.delete(section.entries[index]) }
                                }
                            }
                        }
                    }
                    .searchable(text: $search, prompt: "Search entries")
                }
            }
            .paperBackground()
            .navigationTitle("Journal")
            .toolbar {
                Button {
                    isWriting = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New entry")
            }
            .sheet(isPresented: $isWriting) {
                JournalEditorView()
            }
        }
    }
}

private struct JournalRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(entry.createdAt.formatted(.dateTime.day()))
                    .font(Theme.serif(.title2, weight: .semibold))
                Text(entry.createdAt.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayTitle)
                        .font(Theme.serif(.headline))
                        .lineLimit(1)
                    Spacer()
                    if entry.isCloseOut {
                        Text("\(entry.points) pts")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                    Text(entry.mood.emoji)
                }
                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Larger card used on the Today screen.
struct JournalCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.mood.emoji)
            }
            Text(entry.displayTitle)
                .font(Theme.serif(.headline))
            if !entry.body.isEmpty {
                Text(entry.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .card()
    }
}
