import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var reminders: [Reminder]

    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case journal(prompt: String?), note, reminder
        var id: String {
            switch self {
            case .journal: "journal"
            case .note: "note"
            case .reminder: "reminder"
            }
        }
    }

    private var todaysReminders: [Reminder] {
        reminders
            .filter { !$0.isCompleted && ($0.isDueToday || $0.isOverdue) }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var wroteToday: Bool {
        entries.first.map { Calendar.current.isDateInToday($0.createdAt) } ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    promptCard
                    quickActions
                    remindersSection
                    if let latest = entries.first {
                        recentEntry(latest)
                    }
                }
                .padding()
            }
            .paperBackground()
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .journal(let prompt): JournalEditorView(prompt: prompt)
                case .note: NoteEditorView()
                case .reminder: ReminderEditorView()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(Theme.serif(.largeTitle, weight: .semibold))
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }

    private var promptCard: some View {
        Button {
            sheet = .journal(prompt: Prompts.today)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Label(wroteToday ? "You wrote today. Nice." : "Today's prompt", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text(Prompts.today)
                    .font(Theme.serif(.title3))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text("Tap to write")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(title: "Journal", symbol: "pencil.line") { sheet = .journal(prompt: nil) }
            QuickAction(title: "Note", symbol: "note.text.badge.plus") { sheet = .note }
            QuickAction(title: "Reminder", symbol: "bell.badge") { sheet = .reminder }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On deck")
                .font(Theme.serif(.title3, weight: .semibold))
            VStack(alignment: .leading, spacing: 0) {
                if todaysReminders.isEmpty {
                    Text("Nothing due today. Enjoy the quiet.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(todaysReminders) { reminder in
                        ReminderRow(reminder: reminder)
                        if reminder.id != todaysReminders.last?.id { Divider() }
                    }
                }
            }
            .card()
        }
    }

    private func recentEntry(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last entry")
                .font(Theme.serif(.title3, weight: .semibold))
            NavigationLink {
                JournalDetailView(entry: entry)
            } label: {
                JournalCard(entry: entry)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct QuickAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}
