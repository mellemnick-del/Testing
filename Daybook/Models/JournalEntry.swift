import Foundation
import SwiftData

@Model
final class JournalEntry {
    var createdAt: Date
    var title: String
    var body: String
    var moodRaw: String

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
        title.isEmpty ? createdAt.formatted(.dateTime.weekday(.wide)) : title
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
