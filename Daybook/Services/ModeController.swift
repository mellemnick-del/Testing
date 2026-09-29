import SwiftUI

enum AppMode: String {
    case work, home

    var label: String { self == .work ? "Work mode" : "Home mode" }
    var symbol: String { self == .work ? "briefcase.fill" : "house.fill" }
    var other: AppMode { self == .work ? .home : .work }
}

/// Decides whether it's work time or home time. A manual switch wins until
/// the next scheduled change, then an active Focus filter, then work hours.
/// Home mode hides work reminders so work stays at work.
@Observable
@MainActor
final class ModeController {
    static let shared = ModeController()

    enum Source { case manual, focus, schedule }

    enum Keys {
        static let enabled = "modesEnabled"
        static let workStart = "workStartMinutes"
        static let workEnd = "workEndMinutes"
        static let workDays = "workDays"
        static let focusMode = "focusMode"
        static let manualMode = "manualMode"
        static let manualUntil = "manualModeUntil"
    }

    /// `nil` when work and home modes are turned off.
    private(set) var mode: AppMode?
    private(set) var source: Source = .schedule

    private init() { refresh() }

    // MARK: Settings (shared with SettingsView through @AppStorage)

    nonisolated static var isEnabled: Bool { UserDefaults.standard.object(forKey: Keys.enabled) as? Bool ?? true }
    nonisolated static var workStart: Int { UserDefaults.standard.object(forKey: Keys.workStart) as? Int ?? 8 * 60 }
    nonisolated static var workEnd: Int { UserDefaults.standard.object(forKey: Keys.workEnd) as? Int ?? 17 * 60 + 30 }
    nonisolated static var workDays: Set<Int> {
        let raw = UserDefaults.standard.string(forKey: Keys.workDays) ?? "2,3,4,5,6"
        return Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    // MARK: State

    func refresh(now: Date = .now) {
        let defaults = UserDefaults.standard
        guard Self.isEnabled else {
            mode = nil
            return
        }
        if let raw = defaults.string(forKey: Keys.manualMode), let manual = AppMode(rawValue: raw),
           defaults.double(forKey: Keys.manualUntil) > now.timeIntervalSince1970 {
            mode = manual
            source = .manual
        } else if let raw = defaults.string(forKey: Keys.focusMode), let focus = AppMode(rawValue: raw) {
            mode = focus
            source = .focus
        } else {
            mode = Self.scheduledMode(at: now)
            source = .schedule
        }
    }

    func switchMode(to newMode: AppMode) {
        let until = Self.nextChange(after: .now) ?? .now.addingTimeInterval(12 * 3600)
        UserDefaults.standard.set(newMode.rawValue, forKey: Keys.manualMode)
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: Keys.manualUntil)
        refresh()
    }

    func resumeAutomatic() {
        UserDefaults.standard.removeObject(forKey: Keys.manualMode)
        UserDefaults.standard.removeObject(forKey: Keys.manualUntil)
        refresh()
    }

    /// Short status for the Today pill, like "Home mode · until 8:00 AM".
    var status: String? {
        guard let mode else { return nil }
        switch source {
        case .focus:
            return "\(mode.label) · Focus"
        case .manual:
            let until = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: Keys.manualUntil))
            return "\(mode.label) · until \(Self.shortTime(until))"
        case .schedule:
            guard let next = Self.nextChange(after: .now) else { return mode.label }
            return "\(mode.label) · until \(Self.shortTime(next))"
        }
    }

    // MARK: Schedule math

    nonisolated static func scheduledMode(at date: Date) -> AppMode {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let isWorkday = workDays.contains(parts.weekday ?? 0)
        return isWorkday && minutes >= workStart && minutes < workEnd ? .work : .home
    }

    /// The next moment the schedule flips between work and home.
    nonisolated static func nextChange(after date: Date) -> Date? {
        guard !workDays.isEmpty, workStart < workEnd else { return nil }
        let calendar = Calendar.current
        let current = scheduledMode(at: date)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)),
                  workDays.contains(calendar.component(.weekday, from: day)) else { continue }
            for minutes in [workStart, workEnd] {
                guard let candidate = calendar.date(byAdding: .minute, value: minutes, to: day) else { continue }
                if candidate > date && scheduledMode(at: candidate) != current { return candidate }
            }
        }
        return nil
    }

    private static func shortTime(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(date: .omitted, time: .shortened)
            : date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}

extension Reminder {
    /// Home mode hides work reminders. Everything else always shows.
    func isVisible(in mode: AppMode?) -> Bool {
        !(mode == .home && category == .work)
    }
}
