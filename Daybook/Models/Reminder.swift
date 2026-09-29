import Foundation
import SwiftData

@Model
final class Reminder {
    var createdAt: Date = Date.now
    var title: String = ""
    var notes: String = ""
    var dueDate: Date?
    /// Only used for one-off reminders. Repeating reminders are "done" when
    /// `completedAt` falls on today, so they reset on their own each day.
    var isCompleted: Bool = false
    var completedAt: Date?
    var repeatRaw: String = "never"
    var categoryRaw: String = "personal"
    var effortRaw: String = "medium"
    /// The `FamilyMember.memberID` this is assigned to, or `nil` for you.
    var assigneeID: String?
    /// Stable identifier used for the scheduled local notification.
    var notificationID: String = UUID().uuidString

    init(
        title: String = "",
        notes: String = "",
        dueDate: Date? = nil,
        repeatRule: RepeatRule = .never,
        category: ReminderCategory = .personal,
        effort: Effort = .medium,
        assigneeID: String? = nil
    ) {
        self.createdAt = .now
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = false
        self.repeatRaw = repeatRule.rawValue
        self.categoryRaw = category.rawValue
        self.effortRaw = effort.rawValue
        self.assigneeID = assigneeID
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

    var effort: Effort {
        get { Effort(rawValue: effortRaw) ?? .medium }
        set { effortRaw = newValue.rawValue }
    }

    var isDone: Bool {
        if repeatRule == .never { return isCompleted }
        return completedAt.map(Calendar.current.isDateInToday) ?? false
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted, repeatRule == .never else { return false }
        return dueDate < Calendar.current.startOfDay(for: .now)
            || (Calendar.current.isDateInToday(dueDate) && dueDate < .now)
    }

    /// True when this reminder belongs on today's list, including repeats.
    var isScheduledToday: Bool {
        guard let dueDate else { return false }
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        guard dueDate < startOfTomorrow else { return false }
        switch repeatRule {
        case .never: return calendar.isDateInToday(dueDate)
        case .daily: return true
        case .weekdays: return !calendar.isDateInWeekend(.now)
        case .weekly: return calendar.component(.weekday, from: dueDate) == calendar.component(.weekday, from: .now)
        }
    }

    /// Minutes after midnight, for ordering today's list by time.
    var minuteOfDay: Int {
        guard let dueDate else { return .max }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
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

/// How big a task is. Sizes instead of custom numbers keep scoring effortless.
enum Effort: String, CaseIterable, Identifiable {
    case quick, medium, big

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var points: Int {
        switch self {
        case .quick: 1
        case .medium: 3
        case .big: 5
        }
    }
}
