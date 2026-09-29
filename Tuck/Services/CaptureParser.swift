import Foundation

enum CaptureKind: String, CaseIterable, Identifiable {
    case reminder, note, journal

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .reminder: "bell"
        case .note: "note.text"
        case .journal: "book.closed"
        }
    }
}

struct CaptureResult: Equatable {
    var kind: CaptureKind = .note
    var title: String = ""
    var dueDate: Date?
    var category: ReminderCategory = .personal
    var effort: Effort = .medium
    var mood: Mood = .good
    /// A family member's name found in the text, for assigning chores.
    var assigneeName: String?
}

/// Sorts free-form text into a reminder, note, or journal line.
/// Runs instantly and offline on every iOS version. `SmartCapture` can
/// refine the result with Apple's on-device model where it's available.
enum CaptureParser {
    static func parse(_ raw: String, memberNames: [String] = []) -> CaptureResult {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = CaptureResult()
        guard !text.isEmpty else { return result }

        // "Jake, mow the lawn Saturday" is a chore for Jake.
        let named = findMember(in: text, names: memberNames)
        result.assigneeName = named.name
        if named.leading, let name = named.name {
            text = String(text.dropFirst(name.count)).trimmingCharacters(in: CharacterSet(charactersIn: " ,:-"))
            if text.lowercased().hasPrefix("to ") { text = String(text.dropFirst(3)) }
        }
        let lower = text.lowercased()

        let detected = detectDate(in: text)
        result.category = category(for: lower)
        result.effort = effort(for: lower)
        result.mood = mood(for: lower)

        let taskLike = startsLikeTask(lower)
        if soundsLikeJournal(lower) && !taskLike {
            result.kind = .journal
        } else if detected.date != nil || taskLike || named.leading {
            result.kind = .reminder
        } else {
            result.kind = .note
        }

        // Kept for every kind so switching to Reminder in the UI keeps them.
        result.dueDate = detected.date
        result.title = cleanTitle(text, removing: detected.range)
        return result
    }

    // MARK: Family

    /// Finds a family member's name as a whole word. `leading` is true when
    /// the text starts with it, which reads as an instruction to that person.
    static func findMember(in text: String, names: [String]) -> (name: String?, leading: Bool) {
        let lower = text.lowercased()
        let words = Set(lower.split(whereSeparator: { !$0.isLetter && $0 != "'" }).map { $0.replacingOccurrences(of: "'s", with: "") })
        for name in names where !name.isEmpty {
            let lowerName = name.lowercased()
            if lower.hasPrefix(lowerName) {
                let next = lower.dropFirst(lowerName.count).first
                if next == nil || next == " " || next == "," || next == ":" { return (name, true) }
            }
            if words.contains(lowerName) { return (name, false) }
        }
        return (nil, false)
    }

    // MARK: Dates

    static func detectDate(in text: String) -> (date: Date?, range: Range<String.Index>?) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let match = detector.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              var date = match.date,
              let range = Range(match.range, in: text)
        else { return (nil, nil) }

        let phrase = text[range].lowercased()
        let calendar = Calendar.current
        let timeWords = ["noon", "morning", "afternoon", "evening", "tonight", "night", "am", "pm"]
        let hasTime = phrase.rangeOfCharacter(from: .decimalDigits) != nil || timeWords.contains { phrase.contains($0) }

        if !hasTime {
            // "Thursday" with no time: default to 9 AM rather than noon.
            date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        } else if calendar.component(.hour, from: date) < 7, !phrase.contains("am") {
            // "Pick up Jake at 3" almost always means 3 PM.
            date = calendar.date(byAdding: .hour, value: 12, to: date) ?? date
        }
        return (date, range)
    }

    // MARK: Kind

    private static let leadIns = [
        "remind me to ", "remind me ", "don't forget to ", "dont forget to ", "don't forget ",
        "i need to ", "need to ", "i have to ", "have to ", "i must ", "todo: ", "to do: ", "todo ",
    ]

    private static let taskVerbs: Set<String> = [
        "call", "text", "email", "buy", "pick", "sign", "pay", "book", "schedule", "send", "submit",
        "renew", "return", "order", "finish", "clean", "mow", "fix", "drop", "get", "take", "bring",
        "make", "reply", "cancel", "confirm", "pack", "print", "register", "grab", "remind", "todo",
    ]

    static func startsLikeTask(_ lower: String) -> Bool {
        if leadIns.contains(where: { lower.hasPrefix($0) }) { return true }
        let firstWord = lower.split(whereSeparator: { !$0.isLetter }).first.map(String.init) ?? ""
        return taskVerbs.contains(firstWord)
    }

    static func soundsLikeJournal(_ lower: String) -> Bool {
        let signals = [
            "i feel", "i felt", "feeling", "today was", "tonight was", "grateful", "thankful", "proud",
            "i'm so", "i am so", "i was", "we had", "i loved", "frustrat", "stress", "exhausted",
            "happy", "sad", "tired", "anxious", "excited", "best part", "worst part", "what a day",
        ]
        return signals.contains(where: { lower.contains($0) })
    }

    // MARK: Details

    static func category(for lower: String) -> ReminderCategory {
        let family = [
            "kid", "school", "mom", "dad", "wife", "husband", "son", "daughter", "soccer", "practice",
            "dentist", "doctor", "pediatric", "daycare", "teacher", "field trip", "birthday", "family",
            "baby", "homework", "pickup", "pick up", "grandma", "grandpa", "carpool", "vet",
        ]
        let work = [
            "meeting", "client", "report", "deck", "slides", "presentation", "boss", "team", "standup",
            "deadline", "invoice", "expense", "project", "manager", "1:1", "review", "proposal",
            "office", "work", "quarter", "q1", "q2", "q3", "q4",
        ]
        let familyHits = family.filter { lower.contains($0) }.count
        let workHits = work.filter { lower.contains($0) }.count
        if familyHits == 0 && workHits == 0 { return .personal }
        return familyHits >= workHits ? .family : .work
    }

    static func effort(for lower: String) -> Effort {
        let big = ["clean out", "deep clean", "garage", "taxes", "finish", "proposal", "organize", "move", "paint", "yard", "closet", "plan "]
        let quick = ["call", "text", "email", "sign", "pay", "reply", "send", "book", "order", "confirm", "cancel", "renew"]
        if big.contains(where: { lower.contains($0) }) { return .big }
        if quick.contains(where: { lower.contains($0) }) { return .quick }
        return .medium
    }

    static func mood(for lower: String) -> Mood {
        if ["awful", "terrible", "horrible", "worst", "angry", "exhausted"].contains(where: { lower.contains($0) }) { return .rough }
        if ["tired", "stress", "sad", "frustrat", "anxious", "long day", "hard day"].contains(where: { lower.contains($0) }) { return .low }
        if ["great", "amazing", "proud", "happy", "grateful", "thankful", "loved", "fun", "excited", "awesome"].contains(where: { lower.contains($0) }) { return .great }
        if ["meh", "fine", "okay", "ok day"].contains(where: { lower.contains($0) }) { return .okay }
        return .good
    }

    // MARK: Titles

    static func cleanTitle(_ text: String, removing range: Range<String.Index>?) -> String {
        var title = text
        if let range { title.removeSubrange(range) }

        for leadIn in leadIns where title.lowercased().hasPrefix(leadIn) {
            title.removeFirst(leadIn.count)
            break
        }

        let connectors: Set<String> = ["by", "on", "at", "before", "this", "next", "for", "due", "until", "around"]
        var words = title.split(separator: " ").map(String.init)
        while let last = words.last?.lowercased().trimmingCharacters(in: .punctuationCharacters),
              connectors.contains(last) || last.isEmpty {
            words.removeLast()
        }
        title = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard let first = title.first else { return text }
        return first.uppercased() + title.dropFirst()
    }

    static func firstLine(_ text: String) -> String {
        let line = text.split(separator: "\n").first.map(String.init) ?? text
        return line.count > 60 ? String(line.prefix(60)) + "…" : line
    }
}
