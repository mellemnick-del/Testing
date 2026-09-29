import Foundation
import SwiftData

@Model
final class JournalEntry {
    var createdAt: Date = Date.now
    var title: String = ""
    var body: String = ""
    var moodRaw: String = "good"
    /// Set on entries written through the Evening Close-Out.
    var isCloseOut: Bool = false
    var points: Int = 0
    var doneItems: [String] = []

    init(createdAt: Date = .now, title: String = "", body: String = "", mood: Mood = .good) {
        self.createdAt = createdAt
        self.title = title
        self.body = body
        self.moodRaw = mood.rawValue
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .good }
        set { moodRaw = newValue.rawValue }
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        let weekday = createdAt.formatted(.dateTime.weekday(.wide))
        return isCloseOut ? "\(weekday) close-out" : weekday
    }
}

enum Mood: String, CaseIterable, Identifiable {
    case great, good, okay, low, rough

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: "😄"
        case .good: "🙂"
        case .okay: "😐"
        case .low: "😔"
        case .rough: "😣"
        }
    }

    var label: String { rawValue.capitalized }
}
