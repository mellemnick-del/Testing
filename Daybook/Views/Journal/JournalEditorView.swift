import SwiftUI

struct JournalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let entry: JournalEntry?
    private let prompt: String?

    @State private var title: String
    @State private var bodyText: String
    @State private var mood: Mood
    @FocusState private var bodyFocused: Bool

    init(entry: JournalEntry? = nil, prompt: String? = nil) {
        self.entry = entry
        self.prompt = prompt
        _title = State(initialValue: entry?.title ?? "")
        _bodyText = State(initialValue: entry?.body ?? "")
        _mood = State(initialValue: entry?.mood ?? .good)
    }

    private var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text((entry?.createdAt ?? .now).formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    moodPicker

                    if let prompt {
                        Text(prompt)
                            .font(Theme.serif(.callout))
                            .italic()
                            .foregroundStyle(Theme.accent)
                    }

                    TextField("Title", text: $title)
                        .font(Theme.serif(.title, weight: .semibold))
                        .submitLabel(.next)
                        .onSubmit { bodyFocused = true }

                    TextField("What's on your mind?", text: $bodyText, axis: .vertical)
                        .font(Theme.serif(.body))
                        .lineSpacing(6)
                        .focused($bodyFocused)
                        .frame(minHeight: 240, alignment: .top)
                }
                .padding()
            }
            .paperBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(isEmpty)
                }
            }
            .onAppear { if entry == nil { bodyFocused = true } }
        }
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MoodPicker(mood: $mood)
        }
    }

    private func save() {
        let target = entry ?? JournalEntry()
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        target.mood = mood
        if entry == nil { context.insert(target) }
        dismiss()
    }
}
