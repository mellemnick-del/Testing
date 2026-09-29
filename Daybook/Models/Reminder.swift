import Foundation
import SwiftData

@Model
final class Reminder {
    var createdAt: Date
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var repeatRaw: String
    var categoryRaw: String
    /// Stable identifier used for the scheduled local notification.
    var notificationID: String

    init(
        title: String = "",
        notes: String = "",
        dueDate: Date? = nil,
        repeatRule: RepeatRule = .never,
        category: ReminderCategory = .personal
    ) {
        self.createdAt = .now
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = false
        self.repeatRaw = repeatRule.rawValue
        self.categoryRaw = category.rawValue
        self.notificationID = UUID().uuidString
    }

    var repeatRule: RepeatRule {
        get { RepeatRule(rawValue: repeatRaw) ?? .never }
        set { repeatRaw = newValue.rawValue }
    }

    var category: ReminderCategory {
        get { ReminderCategory(rawValue: categoryRaw) ?? .personal }
        set { categoryRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted, repeatRule == .never else { return false }
        return dueDate < .now
    }

    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
}

enum RepeatRule: String, CaseIterable, Identifiable {
    case never, daily, weekdays, weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .never: "Never"
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekly: "Every week"
        }
    }
}

enum ReminderCategory: String, CaseIterable, Identifiable {
    case work, family, personal

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .work: "briefcase"
        case .family: "house"
        case .personal: "person"
        }
    }
}
