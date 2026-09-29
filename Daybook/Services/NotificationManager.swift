import Foundation
import UserNotifications

/// Schedules and cancels local notifications for reminders.
/// Permission is requested the first time a user sets a time on a reminder,
/// not at launch, which App Review and users both prefer.
@MainActor
enum NotificationManager {
    nonisolated static let closeOutID = "daybook.closeout"

    private static var center: UNUserNotificationCenter { .current() }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func schedule(_ reminder: Reminder) async {
        cancel(reminder)
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return }
        guard await requestAuthorization() else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title.isEmpty ? "Reminder" : reminder.title
        if !reminder.notes.isEmpty { content.body = reminder.notes }
        content.sound = .default

        let calendar = Calendar.current
        var requests: [UNNotificationRequest] = []

        switch reminder.repeatRule {
        case .never:
            guard dueDate > .now else { return }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            requests.append(.init(identifier: reminder.notificationID, content: content, trigger: trigger))
        case .daily:
            let parts = calendar.dateComponents([.hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
            requests.append(.init(identifier: reminder.notificationID, content: content, trigger: trigger))
        case .weekly:
            let parts = calendar.dateComponents([.weekday, .hour, .minute], from: dueDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
            requests.append(.init(identifier: reminder.notificationID, content: content, trigger: trigger))
        case .weekdays:
            // Monday (2) through Friday (6), one repeating request per day.
            for weekday in 2...6 {
                var parts = calendar.dateComponents([.hour, .minute], from: dueDate)
                parts.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
                requests.append(.init(identifier: "\(reminder.notificationID)-\(weekday)", content: content, trigger: trigger))
            }
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    static func cancel(_ reminder: Reminder) {
        let ids = [reminder.notificationID] + (2...6).map { "\(reminder.notificationID)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: Nightly close-out nudge

    /// Repeats every day at the given time. Returns false if notifications are off.
    @discardableResult
    static func scheduleCloseOutNudge(minutesAfterMidnight minutes: Int) async -> Bool {
        guard await requestAuthorization() else { return false }
        cancelCloseOutNudge()

        let content = UNMutableNotificationContent()
        content.title = "Close out your day"
        content.body = "Two minutes: see your score, clear what's left, and write one line."
        content.sound = .default

        var parts = DateComponents()
        parts.hour = minutes / 60
        parts.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        try? await center.add(.init(identifier: closeOutID, content: content, trigger: trigger))
        return true
    }

    static func cancelCloseOutNudge() {
        center.removePendingNotificationRequests(withIdentifiers: [closeOutID])
    }
}
