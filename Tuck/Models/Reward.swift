import Foundation
import SwiftData

/// A goal like "100 points = pizza night". Progress counts points earned
/// since the reward was set up, by one person or the whole family.
@Model
final class Reward {
    var title: String = ""
    var cost: Int = 50
    /// `nil` means the whole family works toward it together.
    var memberID: String?
    var startedAt: Date = Date.now
    var claimedAt: Date?

    init(title: String, cost: Int, memberID: String? = nil) {
        self.title = title
        self.cost = cost
        self.memberID = memberID
        self.startedAt = .now
    }

    var isClaimed: Bool { claimedAt != nil }

    func progress(from completions: [TaskCompletion]) -> Int {
        completions
            .filter { $0.completedAt >= startedAt && (memberID == nil || $0.assigneeID == memberID) }
            .reduce(0) { $0 + $1.points }
    }

    /// Starts the same reward over, for weekly treats.
    func restart() {
        startedAt = .now
        claimedAt = nil
    }
}
