import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let reminder: Reminder?

    @State private var title: String
    @State private var notes: String
    @State private var hasDate: Bool
    @State private var dueDate: Date
    @State private var repeatRule: RepeatRule
    @State private var category: ReminderCategory

    init(reminder: Reminder? = nil, category: ReminderCategory = .personal) {
        self.reminder = reminder
        _title = State(initialValue: reminder?.title ?? "")
        _notes = State(initialValue: reminder?.notes ?? "")
        _hasDate = State(initialValue: reminder?.dueDate != nil)
        _dueDate = State(initialValue: reminder?.dueDate ?? Self.nextRoundHour())
        _repeatRule = State(initialValue: reminder?.repeatRule ?? .never)
        _category = State(initialValue: reminder?.category ?? category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you need to remember?", text: $title)
                        .font(Theme.serif(.title3))
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section {
                    Picker("List", selection: $category) {
                        ForEach(ReminderCategory.allCases) { option in
                            Label(option.label, systemImage: option.symbol).tag(option)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $hasDate.animation()) {
                        Label("Remind me", systemImage: "bell")
                    }
                    if hasDate {
                        DatePicker("When", selection: $dueDate)
                        Picker("Repeat", selection: $repeatRule) {
                            ForEach(RepeatRule.allCases) { rule in
                                Text(rule.label).tag(rule)
                            }
                        }
                    }
                } footer: {
                    if hasDate {
                        Text("You'll get a notification at this time.")
                    }
                }
            }
            .paperBackground()
            .navigationTitle(reminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let target = reminder ?? Reminder()
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.dueDate = hasDate ? dueDate : nil
        target.repeatRule = hasDate ? repeatRule : .never
        target.category = category
        if reminder == nil { context.insert(target) }
        Task { await NotificationManager.schedule(target) }
        dismiss()
    }

    private static func nextRoundHour() -> Date {
        let calendar = Calendar.current
        let next = calendar.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return calendar.date(bySetting: .minute, value: 0, of: next) ?? next
    }
}
