import SwiftUI

/// A colored initial for a family member, or a person icon for you.
struct MemberAvatar: View {
    let name: String?
    let tint: Color
    var size: CGFloat = 32

    init(member: FamilyMember?, size: CGFloat = 32) {
        self.name = member?.name
        self.tint = member?.color.color ?? Theme.accent
        self.size = size
    }

    init(name: String, color: MemberColor, size: CGFloat = 32) {
        self.name = name
        self.tint = color.color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.18))
            if let name {
                Text(name.first.map { String($0).uppercased() } ?? "?")
                    .font(.system(size: size * 0.45, weight: .semibold, design: .rounded))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
            }
        }
        .foregroundStyle(tint)
        .frame(width: size, height: size)
        .accessibilityLabel(name ?? "You")
    }
}
