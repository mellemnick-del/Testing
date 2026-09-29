import Foundation
import SwiftData

/// In-memory sample data for Xcode previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: JournalEntry.self, Note.self, Reminder.self, TaskCompletion.self, FamilyMember.self, Reward.self,
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
        let fieldTrip = Reminder(title: "Sign field trip form", dueDate: .now.addingTimeInterval(3600 * 2), category: .family, effort: .quick)
        let update = Reminder(title: "Post standup notes", dueDate: .now.addingTimeInterval(-3600), repeatRule: .daily, category: .work)
        let garage = Reminder(title: "Clean out the garage", dueDate: .now.addingTimeInterval(-3600 * 3), category: .family, effort: .big)
        let expenses = Reminder(title: "Submit expense report", dueDate: .now.addingTimeInterval(-3600 * 26), category: .work)
        let callMom = Reminder(title: "Call Mom", category: .personal, effort: .quick)
        for reminder in [fieldTrip, update, garage, expenses, callMom] { context.insert(reminder) }
        update.markDone(in: context)
        garage.markDone(in: context)

        // Family
        let emma = FamilyMember(name: "Emma", color: .pink)
        let jake = FamilyMember(name: "Jake", color: .blue)
        context.insert(emma)
        context.insert(jake)
        let bed = Reminder(title: "Make bed", dueDate: .now, repeatRule: .daily, category: .family, effort: .quick, assigneeID: emma.memberID)
        let dishes = Reminder(title: "Unload dishwasher", dueDate: .now, repeatRule: .daily, category: .family, assigneeID: emma.memberID)
        let lawn = Reminder(title: "Mow the lawn", dueDate: .now, category: .family, effort: .big, assigneeID: jake.memberID)
        let trash = Reminder(title: "Take out the trash", dueDate: .now, category: .family, effort: .quick, assigneeID: jake.memberID)
        for chore in [bed, dishes, lawn, trash] { context.insert(chore) }
        bed.markDone(in: context)
        lawn.markDone(in: context)
        let pizza = Reward(title: "Pizza night", cost: 100)
        pizza.startedAt = Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now
        context.insert(pizza)
        context.insert(Reward(title: "Pick Friday's movie", cost: 30, memberID: jake.memberID))

        // A few past days of points so personal bests have history.
        let history: [(daysAgo: Int, points: [Int])] = [(1, [3, 3, 1]), (2, [5, 3]), (3, [1, 1, 3]), (7, [3, 5])]
        for day in history {
            for points in day.points {
                let past = Reminder(title: "Earlier task", effort: points == 5 ? .big : points == 1 ? .quick : .medium)
                let date = Calendar.current.date(byAdding: .day, value: -day.daysAgo, to: .now) ?? .now
                context.insert(TaskCompletion(reminder: past, at: date))
            }
        }
        return container
    }()
}
