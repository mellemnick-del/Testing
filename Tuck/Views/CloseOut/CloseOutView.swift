import SwiftUI
import SwiftData

/// The two-minute nightly wrap-up: see what you got done, roll or drop
/// what's left, and save one line about the day to the journal.
struct CloseOutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TaskCompletion.completedAt) private var completions: [TaskCompletion]
    @Query private var reminders: [Reminder]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var step: Step = .done
    @State private var mood: Mood = .good
    @State private var line = ""
    @State private var didLoad = false

    private enum Step: Int, CaseIterable {
        case done, leftover, reflect
    }

    private var stats: ScoreStats { ScoreStats(completions: completions.mine) }

    /// Points family members earned today, shown as a bonus line.
    private var familyToday: Int {
        completions
            .filter { $0.assigneeID != nil && Calendar.current.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + $1.points }
    }

    private var todaysCompletions: [TaskCompletion] {
        completions.mine.filter { Calendar.current.isDateInToday($0.completedAt) }
    }

    /// One-off reminders due today or earlier that didn't get done.
    /// Repeating reminders reset on their own, so they never pile up here.
    private var leftovers: [Reminder] {
        reminders
            .filter { $0.assigneeID == nil && !$0.isDone && $0.repeatRule == .never && ($0.isScheduledToday || $0.isOverdue) }
            .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }

    private var existingEntry: JournalEntry? {
        entries.first { $0.isCloseOut && Calendar.current.isDateInToday($0.createdAt) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progress
                ScrollView {
                    Group {
                        switch step {
                        case .done: doneStep
                        case .leftover: leftoverStep
                        case .reflect: reflectStep
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
                primaryButton
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Close out your day").font(Theme.serif(.headline))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
                if step != .done {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Back") { move(by: -1) }
                    }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    // MARK: Steps

    private var doneStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DONE TODAY")
                    .font(.caption.weight(.semibold)).tracking(1.2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(stats.today)")
                        .font(.system(size: 64, weight: .semibold, design: .serif))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(stats.today == 1 ? "point" : "points")
                        .font(Theme.serif(.title3))
                        .foregroundStyle(.secondary)
                }
                Text(stats.highlight)
                    .font(Theme.serif(.title3))
                    .foregroundStyle(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 0) {
                if todaysCompletions.isEmpty {
                    Text("Nothing checked off today. That's okay.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(todaysCompletions) { completion in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                            Text(completion.title)
                            Spacer()
                            PointsBadge(points: completion.points, earned: true)
                        }
                        .padding(.vertical, 8)
                        if completion.id != todaysCompletions.last?.id { Divider() }
                    }
                }
            }
            .card()

            if familyToday > 0 {
                Label("Your family earned \(familyToday) points on chores today.", systemImage: "house")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: 12) {
                StatTile(value: stats.thisWeek, label: "This week")
                StatTile(value: stats.lifetime, label: "All time")
            }

            if let next = stats.nextMilestone {
                MilestoneBar(current: stats.lifetime, target: next)
            }
        }
    }

    private var leftoverStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Roll it or drop it")
                    .font(Theme.serif(.title, weight: .semibold))
                Text("Anything unfinished moves to tomorrow, or goes away for good. Either way, it's off your mind tonight.")
                    .foregroundStyle(.secondary)
            }

            if leftovers.isEmpty {
                Label("Nothing left over. Clean slate.", systemImage: "sparkles")
                    .foregroundStyle(Theme.accent)
                    .card()
            } else {
                ForEach(leftovers) { reminder in
                    LeftoverRow(reminder: reminder) {
                        withAnimation { reminder.rollToTomorrow() }
                    } onDrop: {
                        withAnimation {
                            NotificationManager.cancel(reminder)
                            context.delete(reminder)
                        }
                    }
                }
                if leftovers.count > 1 {
                    Button {
                        withAnimation { leftovers.forEach { $0.rollToTomorrow() } }
                    } label: {
                        Label("Roll all to tomorrow", systemImage: "arrow.uturn.forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
    }

    private var reflectStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("How did today feel?")
                    .font(Theme.serif(.title, weight: .semibold))
                MoodPicker(mood: $mood)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("One line about today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("The best part was…", text: $line, axis: .vertical)
                    .font(Theme.serif(.title3))
                    .lineLimit(1...5)
                    .card()
            }

            if !todaysCompletions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Saved with this entry")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(todaysCompletions.map(\.title).joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(stats.today) points")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: Chrome

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? Theme.accent : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.snappy, value: step)
    }

    private var primaryButton: some View {
        Button {
            if step == .reflect { save() } else { move(by: 1) }
        } label: {
            Text(step == .reflect ? "Close the day" : "Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .sensoryFeedback(.success, trigger: step)
    }

    private func move(by offset: Int) {
        guard let next = Step(rawValue: step.rawValue + offset) else { return }
        withAnimation(.snappy) { step = next }
    }

    private func loadExisting() {
        guard !didLoad else { return }
        didLoad = true
        if let entry = existingEntry {
            mood = entry.mood
            line = entry.body
        }
    }

    private func save() {
        let entry = existingEntry ?? JournalEntry()
        entry.isCloseOut = true
        entry.body = line.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = mood
        entry.points = stats.today
        entry.doneItems = todaysCompletions.map(\.title)
        if existingEntry == nil { context.insert(entry) }
        dismiss()
    }
}

// MARK: - Pieces

struct PointsBadge: View {
    let points: Int
    var earned = false

    var body: some View {
        Text("+\(points)")
            .font(.caption.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(earned ? Theme.accent : .secondary)
            .background(
                Capsule().fill(earned ? Theme.accent.opacity(0.14) : Color.secondary.opacity(0.1))
            )
            .accessibilityLabel("\(points) points")
    }
}

private struct StatTile: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(Theme.serif(.title, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

private struct MilestoneBar: View {
    let current: Int
    let target: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next milestone")
                    .font(.footnote.weight(.semibold))
                Spacer()
                Text("\(target - current) to go")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(current), total: Double(target))
                .tint(Theme.accent)
            Text("\(target) points")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}

private struct LeftoverRow: View {
    let reminder: Reminder
    let onRoll: () -> Void
    let onDrop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.body.weight(.medium))
                    if let due = reminder.dueDate {
                        Text(due.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                            .font(.caption)
                            .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                    }
                }
                Spacer()
                PointsBadge(points: reminder.effort.points)
            }
            HStack(spacing: 10) {
                Button(action: onRoll) {
                    Label("Tomorrow", systemImage: "arrow.uturn.forward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button(role: .destructive, action: onDrop) {
                    Label("Drop", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
        .card()
    }
}

#Preview {
    CloseOutView()
        .modelContainer(PreviewData.container)
}
