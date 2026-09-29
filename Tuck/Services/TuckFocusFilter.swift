import AppIntents
import Foundation

/// Lets people add Tuck to an iPhone Focus (Settings > Focus > Add Filter).
/// When that Focus turns on, Tuck switches to the chosen mode and only
/// matching reminder notifications come through.
struct TuckFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Set Tuck mode"
    static var description: IntentDescription? = "Show work or home reminders while this Focus is on."

    /// Left empty by the system when the Focus turns off.
    @Parameter(title: "Mode")
    var mode: FocusModeOption?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(mode == .work ? "Work" : "Home") mode")
    }

    /// Notification filtering uses each reminder's `filterCriteria`, which is its list name.
    var appContext: FocusFilterAppContext {
        let allowed: [String]
        switch mode {
        case .work: allowed = ["work", "personal", "family"]
        case .home, nil: allowed = ["personal", "family"]
        }
        return FocusFilterAppContext(notificationFilterPredicate: NSPredicate(format: "SELF IN %@", allowed))
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(mode?.rawValue, forKey: ModeController.Keys.focusMode)
        await ModeController.shared.refresh()
        return .result()
    }
}

enum FocusModeOption: String, AppEnum {
    case work, home

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Mode"
    static var caseDisplayRepresentations: [FocusModeOption: DisplayRepresentation] = [
        .work: "Work",
        .home: "Home",
    ]
}
