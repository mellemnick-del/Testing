import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
                .font(Theme.serif(.title2, weight: .semibold))
        } description: {
            Text(message)
        }
    }
}
