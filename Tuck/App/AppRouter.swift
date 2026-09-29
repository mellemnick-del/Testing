import SwiftUI

/// App-wide navigation, so a notification tap can open the right screen.
@Observable
@MainActor
final class AppRouter {
    static let shared = AppRouter()

    enum Tab: Hashable {
        case today, journal, notes, reminders, family
    }

    var tab: Tab = .today
    var closeOutRequested = false

    func openCloseOut() {
        tab = .today
        closeOutRequested = true
    }
}
