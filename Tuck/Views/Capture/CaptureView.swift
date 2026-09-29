import SwiftUI
import SwiftData

/// One box for anything on your mind. Tuck decides whether it's a
/// reminder, a note, or a journal line, and you can switch it before saving.
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    @State private var text = ""
    @State private var result = CaptureResult()
    @State private var parsedText = ""
    @State private var chosenKind: CaptureKind?
    @State private var savedCount = 0
    @FocusState private var focused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var kind: CaptureKind { chosenKind ?? result.kind }

    private var assignee: FamilyMember? {
        guard let name = result.assigneeName else { return nil }
        return members.first { $0.name == name }
    }

    private func parse(_ text: String) -> CaptureResult {
        CaptureParser.parse(text, memberNames: members.map(\.name))
    }

    private var kindSelection: Binding<CaptureKind> {
        Binding { kind } set: { chosenKind = $0 }
    }

    private static let examples = [
        "Pick up Jake from soccer Friday at 5",
        "Sarah wants more ownership of the launch",
        "Proud of how the kids handled the move today",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("What's on your mind?", text: $text, axis: .vertical)
                        .font(Theme.serif(.title2))
                        .lineLimit(2...8)
                        .focused($focused)
                        .submitLabel(.done)

                    if trimmed.isEmpty {
                        exampleList
                    } else {
                        preview
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
                .animation(.snappy, value: trimmed.isEmpty)
            }
            .paperBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Capture").font(Theme.serif(.headline))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { focused = true }
            .task(id: text) { await reparse() }
            .sensoryFeedback(.success, trigger: savedCount)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Pieces

    private var exampleList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type or tap the mic on your keyboard. Tuck sorts it for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(Self.examples, id: \.self) { example in
                Button {
                    text = example
                } label: {
                    Label(example, systemImage: "arrow.up.left")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Save as", selection: kindSelection) {
                ForEach(CaptureKind.allCases) { option in
                    Label(option.label, systemImage: option.symbol).tag(option)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                switch kind {
                case .reminder: reminderPreview
                case .note: notePreview
                case .journal: journalPreview
                }
            }
            .card()
        }
    }

    private var reminderPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(result.title.isEmpty ? trimmed : result.title)
                    .font(.body.weight(.medium))
                Spacer()
                PointsBadge(points: result.effort.points)
            }
            HStack(spacing: 14) {
                if let due = result.dueDate {
                    Label(due.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute()), systemImage: "calendar")
                } else {
                    Label("No time set", systemImage: "calendar")
                }
                if let assignee {
                    HStack(spacing: 4) {
                        MemberAvatar(member: assignee, size: 16)
                        Text("For \(assignee.name)")
                    }
                } else {
                    Label(result.category.label, systemImage: result.category.symbol)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var notePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(CaptureParser.firstLine(trimmed))
                .font(Theme.serif(.headline))
            Label("Saves to Notes", systemImage: "note.text")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var journalPreview: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(result.mood.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 6) {
                Text(trimmed)
                    .font(Theme.serif(.body))
                    .lineLimit(3)
                Label("Adds to today's journal", systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Logic

    private func reparse() async {
        let snapshot = text
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        withAnimation(.snappy) { result = parse(snapshot) }
        parsedText = snapshot

        // Let the on-device model take a second look once typing pauses.
        guard SmartCapture.isAvailable, snapshot.count > 3 else { return }
        try? await Task.sleep(for: .milliseconds(600))
        guard !Task.isCancelled, let refined = await SmartCapture.refine(snapshot, base: result),
              !Task.isCancelled, snapshot == text else { return }
        withAnimation(.snappy) { result = refined }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        if parsedText != text { result = parse(text) }

        switch kind {
        case .reminder:
            let reminder = Reminder(
                title: result.title.isEmpty ? trimmed : result.title,
                dueDate: result.dueDate,
                category: assignee == nil ? result.category : .family,
                effort: result.effort,
                assigneeID: assignee?.memberID
            )
            context.insert(reminder)
            if reminder.dueDate != nil {
                Task { await NotificationManager.schedule(reminder) }
            }
        case .note:
            context.insert(Note(body: trimmed))
        case .journal:
            context.insert(JournalEntry(body: trimmed, mood: result.mood))
        }
        savedCount += 1
        dismiss()
    }
}

#Preview {
    CaptureView()
        .modelContainer(PreviewData.container)
}
