import Foundation
import SwiftData

/// In-memory sample data for Xcode previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: JournalEntry.self, Note.self, Reminder.self,
            configurations: config
        )
        let context = container.mainContext

        context.insert(JournalEntry(
            createdAt: .now.addingTimeInterval(-3600 * 20),
            title: "Soccer practice and a quiet evening",
            body: "Got out of the office on time for once. The kids ran drills in the rain and loved every minute of it.",
            mood: .great
        ))
        context.insert(JournalEntry(
            createdAt: .now.addingTimeInterval(-3600 * 72),
            title: "Long week",
            body: "Three back to back deadlines. Proud we shipped, need a real weekend.",
            mood: .low
        ))
        context.insert(Note(title: "Groceries", body: "Milk\nEggs\nCoffee beans\nLunchbox snacks", isPinned: true))
        context.insert(Note(title: "Q4 planning takeaways", body: "Focus on retention. Hire one more designer."))
        context.insert(Reminder(title: "Sign field trip form", dueDate: .now.addingTimeInterval(3600 * 2), category: .family))
        context.insert(Reminder(title: "Send weekly update", dueDate: .now.addingTimeInterval(3600 * 5), repeatRule: .weekly, category: .work))
        context.insert(Reminder(title: "Call Mom", category: .personal))
        return container
    }()
}
