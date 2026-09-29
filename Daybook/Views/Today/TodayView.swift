import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var reminders: [Reminder]
    @Query private var completions: [TaskCompletion]

    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case journal(prompt: String?), note, reminder, closeOut, capture, settings
        var id: String {
            switch self {
            case .capture: "capture"
            case .settings: "settings"
            case .journal: "journal"
            case .note: "note"
            case .reminder: "reminder"
            case .closeOut: "closeOut"
            }
        }
    }

    /// Everything on today's plate, open items first, then by time of day.
    private var todaysReminders: [Reminder] {
        reminders
            .filter { $0.assigneeID == nil && ($0.isScheduledToday || $0.isOverdue) }
            .sorted {
                if $0.isDone != $1.isDone { return !$0.isDone }
                if $0.isOverdue != $1.isOverdue { return $0.isOverdue }
                return $0.minuteOfDay < $1.minuteOfDay
            }
    }

    private var stats: ScoreStats { ScoreStats(completions: completions.mine) }

    private var closedToday: Bool {
        entries.contains { $0.isCloseOut && Calendar.current.isDateInToday($0.createdAt) }
    }

    private var isEvening: Bool {
        Calendar.current.component(.hour, from: .now) >= 17
    }

    private var wroteToday: Bool {
        entries.first.map { Calendar.current.isDateInToday($0.createdAt) } ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    captureBar
                    scoreCard
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
                case .closeOut: CloseOutView()
                case .capture: CaptureView()
                case .settings: SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .onAppear(perform: handleCloseOutRequest)
            .onChange(of: router.closeOutRequested) { handleCloseOutRequest() }
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

    private func handleCloseOutRequest() {
        guard router.closeOutRequested else { return }
        router.closeOutRequested = false
        sheet = .closeOut
    }

    private var captureBar: some View {
        Button {
            sheet = .capture
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                Text("What's on your mind?")
                    .font(Theme.serif(.body))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(Theme.card, in: Capsule())
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capture a thought, task, or note")
    }

    private var scoreCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY'S SCORE")
                    .font(.caption.weight(.semibold)).tracking(1.2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(stats.today)")
                        .font(.system(size: 40, weight: .semibold, design: .serif))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: stats.today)
                    Text("pts")
                        .font(Theme.serif(.body))
                        .foregroundStyle(.secondary)
                }
                Text(isEvening && !closedToday ? "Ready to wrap up?" : "\(stats.thisWeek) this week")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                sheet = .closeOut
            } label: {
                Label(closedToday ? "Review day" : "Close out", systemImage: closedToday ? "checkmark.seal" : "moon.stars")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .card()
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
        .environment(AppRouter.shared)
        .modelContainer(PreviewData.container)
}
