import SwiftUI
import SwiftData

/// Someone you assign chores to. "You" is implied: anything with no
/// assignee belongs to the person holding the phone.
@Model
final class FamilyMember {
    var memberID: String = UUID().uuidString
    var name: String = ""
    var colorRaw: String = "teal"
    var createdAt: Date = Date.now

    init(name: String, color: MemberColor = .teal) {
        self.memberID = UUID().uuidString
        self.name = name
        self.colorRaw = color.rawValue
        self.createdAt = .now
    }

    var color: MemberColor {
        get { MemberColor(rawValue: colorRaw) ?? .teal }
        set { colorRaw = newValue.rawValue }
    }

    var initial: String { name.first.map { String($0).uppercased() } ?? "?" }
}

enum MemberColor: String, CaseIterable, Identifiable {
    case teal, blue, orange, pink, purple, indigo

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .teal: .teal
        case .blue: .blue
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .indigo: .indigo
        }
    }
}
