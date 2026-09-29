import Foundation
import SwiftData

/// Completing, un-completing, and rolling reminders. Keeps the points log
/// and scheduled notifications in step with the reminder itself.
@MainActor
extension Reminder {
    func markDone(in context: ModelContext) {
        guard !isDone else { return }
        completedAt = .now
        if repeatRule == .never {
            isCompleted = true
            NotificationManager.cancel(self)
        }
        context.insert(TaskCompletion(reminder: self))
    }

    func markNotDone(in context: ModelContext) {
        guard isDone else { return }
        let id = notificationID
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let todays = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { $0.reminderID == id && $0.completedAt >= startOfToday }
        )
        for completion in (try? context.fetch(todays)) ?? [] {
            context.delete(completion)
        }
        completedAt = nil
        isCompleted = false
        if repeatRule == .never {
            Task { await NotificationManager.schedule(self) }
        }
    }

    func toggleDone(in context: ModelContext) {
        isDone ? markNotDone(in: context) : markDone(in: context)
    }

    /// Moves an unfinished reminder to the same time tomorrow.
    func rollToTomorrow() {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: dueDate ?? .now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) else { return }
        dueDate = calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: tomorrow)
        Task { await NotificationManager.schedule(self) }
    }
}
