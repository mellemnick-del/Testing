import Foundation

/// A rotating daily journaling prompt. Short and doable in a few minutes.
enum Prompts {
    static let all = [
        "What's one thing that went better than expected today?",
        "What made you laugh recently?",
        "What's taking up the most space in your head right now?",
        "Name three small wins from this week.",
        "What would make tomorrow a good day?",
        "Who helped you out lately, and how?",
        "What are you looking forward to?",
        "What's one thing you can let go of today?",
        "Describe a moment today you want to remember.",
        "What did your kids (or you) learn today?",
        "What drained your energy, and what refilled it?",
        "If today had a headline, what would it be?",
        "What's something you're proud of that nobody saw?",
        "What's one boundary you want to protect this week?",
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[day % all.count]
    }
}
