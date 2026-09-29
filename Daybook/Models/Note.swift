import Foundation
import SwiftData

@Model
final class Note {
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var body: String
    var isPinned: Bool

    init(title: String = "", body: String = "", isPinned: Bool = false) {
        self.createdAt = .now
        self.updatedAt = .now
        self.title = title
        self.body = body
        self.isPinned = isPinned
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        let firstLine = body.split(separator: "\n").first.map(String.init) ?? ""
        return firstLine.isEmpty ? "Untitled" : firstLine
    }
}
