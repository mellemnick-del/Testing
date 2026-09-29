import SwiftUI

/// One place for the app's look: warm paper background, soft cards,
/// a calm sage accent, and serif type for anything you write.
enum Theme {
    static let accent = Color.accentColor
    static let paper = Color("Paper")
    static let card = Color("Card")

    static let cornerRadius: CGFloat = 18
    static let spacing: CGFloat = 16

    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.spacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }

    /// Paper background for lists and scroll views.
    func paperBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper.ignoresSafeArea())
    }
}
