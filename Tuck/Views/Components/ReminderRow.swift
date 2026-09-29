import SwiftUI

struct ReminderRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var reminder: Reminder
    /// Shown as a small avatar when the reminder is someone else's chore.
    var assignee: FamilyMember? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { reminder.toggleDone(in: context) }
            } label: {
                Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(reminder.isDone ? Theme.accent : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reminder.isDone ? "Mark incomplete" : "Mark complete")
            .sensoryFeedback(.success, trigger: reminder.isDone) { _, done in done }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title.isEmpty ? "Untitled" : reminder.title)
                    .strikethrough(reminder.isDone)
                    .foregroundStyle(reminder.isDone ? .secondary : .primary)
                if let due = reminder.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: reminder.category.symbol)
                        Text(dueText(due))
                        if reminder.repeatRule != .never {
                            Image(systemName: "repeat")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                }
            }
            Spacer(minLength: 0)
            if let assignee {
                MemberAvatar(member: assignee, size: 24)
            }
            PointsBadge(points: reminder.effort.points, earned: reminder.isDone)
        }
        .padding(.vertical, 4)
    }

    private func dueText(_ date: Date) -> String {
        if reminder.repeatRule != .never || Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute())
    }
}
