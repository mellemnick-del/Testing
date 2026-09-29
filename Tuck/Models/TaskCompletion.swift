import Foundation
import SwiftData

/// A permanent record of points earned. Kept even if the reminder is later
/// deleted, so scores and personal bests never go backwards.
@Model
final class TaskCompletion {
    var title: String = ""
    var points: Int = 0
    var categoryRaw: String = "personal"
    var completedAt: Date = Date.now
    var reminderID: String = ""
    /// Who earned the points. `nil` is you.
    var assigneeID: String?

    init(reminder: Reminder, at date: Date = .now) {
        self.title = reminder.title
        self.points = reminder.effort.points
        self.categoryRaw = reminder.categoryRaw
        self.completedAt = date
        self.reminderID = reminder.notificationID
        self.assigneeID = reminder.assigneeID
    }
}

extension Array where Element == TaskCompletion {
    /// Points you earned yourself, as opposed to family members.
    var mine: [TaskCompletion] { filter { $0.assigneeID == nil } }
}
