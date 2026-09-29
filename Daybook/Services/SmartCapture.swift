import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional upgrade to `CaptureParser` using Apple's on-device model
/// (iOS 26+, Apple Intelligence devices). Free, private, works offline.
/// Dates always come from the rule-based parser, which handles them better.
enum SmartCapture {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func refine(_ text: String, base: CaptureResult) async -> CaptureResult? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await ModelCapture.refine(text, base: base)
        }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private enum ModelCapture {
    @Generable
    enum Kind { case reminder, note, journal }

    @Generable
    enum Category { case work, family, personal }

    @Generable
    enum Size { case quick, medium, big }

    @Generable
    struct Result {
        @Guide(description: "reminder: something the person needs to do. journal: feelings or reflections about their day. note: information to keep, like lists or ideas.")
        var kind: Kind
        @Guide(description: "A short title of at most 8 words, with any date or time removed.")
        var title: String
        var category: Category
        @Guide(description: "How much effort the task takes. quick: a few minutes. big: an hour or more.")
        var size: Size
    }

    static func refine(_ text: String, base: CaptureResult) async -> CaptureResult? {
        let session = LanguageModelSession(instructions: """
            You sort quick thoughts from a busy working parent into a reminder, a note, \
            or a journal line for a personal organizer app.
            """)
        guard let response = try? await session.respond(to: text, generating: Result.self) else { return nil }
        let generated = response.content

        var result = base
        switch generated.kind {
        case .reminder: result.kind = .reminder
        case .note: result.kind = .note
        case .journal: result.kind = .journal
        }
        switch generated.category {
        case .work: result.category = .work
        case .family: result.category = .family
        case .personal: result.category = .personal
        }
        switch generated.size {
        case .quick: result.effort = .quick
        case .medium: result.effort = .medium
        case .big: result.effort = .big
        }
        if !generated.title.isEmpty {
            result.title = generated.title
        }
        return result
    }
}
#endif
