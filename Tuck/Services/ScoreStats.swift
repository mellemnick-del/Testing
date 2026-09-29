import Foundation

/// Scores and personal bests built from the completion log.
/// Deliberately has no streaks: a missed day never takes anything away.
struct ScoreStats {
    static let milestones = [50, 100, 250, 500, 1_000, 2_500, 5_000, 10_000]

    private let calendar = Calendar.current
    private let dailyTotals: [Date: Int]
    private let todayStart: Date

    let today: Int
    let thisWeek: Int
    let lifetime: Int

    init(completions: [TaskCompletion], now: Date = .now) {
        let calendar = Calendar.current
        var totals: [Date: Int] = [:]
        for completion in completions {
            totals[calendar.startOfDay(for: completion.completedAt), default: 0] += completion.points
        }
        dailyTotals = totals
        todayStart = calendar.startOfDay(for: now)
        today = totals[todayStart] ?? 0
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? todayStart
        thisWeek = totals.filter { $0.key >= weekStart }.values.reduce(0, +)
        lifetime = totals.values.reduce(0, +)
    }

    var nextMilestone: Int? {
        Self.milestones.first { $0 > lifetime }
    }

    /// One encouraging line about today. Never negative.
    var highlight: String {
        guard today > 0 else { return "A quiet day counts too. Tomorrow is a fresh start." }

        let previous = dailyTotals.filter { $0.key < todayStart }
        guard !previous.isEmpty else { return "Your first scored day. Nice start." }

        let monthAgo = calendar.date(byAdding: .day, value: -28, to: todayStart) ?? todayStart
        let weekday = calendar.component(.weekday, from: todayStart)
        let sameWeekday = previous
            .filter { $0.key >= monthAgo && calendar.component(.weekday, from: $0.key) == weekday }
            .map(\.value)
        if let best = sameWeekday.max(), today > best {
            return "Your best \(todayStart.formatted(.dateTime.weekday(.wide))) this month."
        }

        let weekAgo = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
        let lastWeek = previous.filter { $0.key >= weekAgo }.map(\.value)
        if let best = lastWeek.max(), today > best {
            return "Your best day this week."
        }

        let average = lastWeek.reduce(0, +) / 7
        if today > average {
            return "\(today - average) points above your daily average."
        }
        return "Steady day. Every point counts."
    }
}
