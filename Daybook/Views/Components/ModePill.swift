import SwiftUI

/// Shows Work or Home mode on Today. Tap to switch until the next scheduled change.
struct ModePill: View {
    private let controller = ModeController.shared

    var body: some View {
        if let mode = controller.mode, let status = controller.status {
            Menu {
                Button("Switch to \(mode.other.label)", systemImage: mode.other.symbol) {
                    withAnimation(.snappy) { controller.switchMode(to: mode.other) }
                }
                if controller.source == .manual {
                    Button("Back to automatic", systemImage: "clock.arrow.circlepath") {
                        withAnimation(.snappy) { controller.resumeAutomatic() }
                    }
                }
            } label: {
                Label(status, systemImage: mode.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHint("Switches between work and home mode")
        }
    }
}
