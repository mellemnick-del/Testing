import SwiftUI

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let note: Note?

    @State private var title: String
    @State private var bodyText: String
    @State private var isPinned: Bool
    @FocusState private var bodyFocused: Bool

    init(note: Note? = nil) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _bodyText = State(initialValue: note?.body ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
    }

    private var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Title", text: $title)
                        .font(Theme.serif(.title2, weight: .semibold))
                        .submitLabel(.next)
                        .onSubmit { bodyFocused = true }

                    TextField("Start typing…", text: $bodyText, axis: .vertical)
                        .font(.body)
                        .lineSpacing(4)
                        .focused($bodyFocused)
                        .frame(minHeight: 300, alignment: .top)
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
                ToolbarItem(placement: .principal) {
                    Button {
                        isPinned.toggle()
                    } label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                    }
                    .accessibilityLabel(isPinned ? "Unpin" : "Pin")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                        .bold()
                        .disabled(isEmpty)
                }
            }
            .onAppear { if note == nil { bodyFocused = true } }
        }
    }

    private func save() {
        let target = note ?? Note()
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.body = bodyText
        target.isPinned = isPinned
        target.updatedAt = .now
        if note == nil { context.insert(target) }
        dismiss()
    }
}
