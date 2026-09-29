import SwiftUI
import SwiftData

struct MemberEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var reminders: [Reminder]

    private let member: FamilyMember?
    @State private var name: String
    @State private var color: MemberColor
    @State private var confirmRemove = false

    init(member: FamilyMember? = nil) {
        self.member = member
        _name = State(initialValue: member?.name ?? "")
        _color = State(initialValue: member?.color ?? MemberColor.allCases.randomElement() ?? .teal)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        MemberAvatar(name: trimmedName.isEmpty ? "?" : trimmedName, color: color, size: 48)
                        TextField("Name", text: $name)
                            .font(Theme.serif(.title3))
                            .textInputAutocapitalization(.words)
                    }
                }
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(MemberColor.allCases) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().strokeBorder(.primary.opacity(color == option ? 0.6 : 0), lineWidth: 2).padding(-4))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.rawValue.capitalized)
                            .accessibilityAddTraits(color == option ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                if member != nil {
                    Section {
                        Button("Remove from family", role: .destructive) { confirmRemove = true }
                    } footer: {
                        Text("Their chores move to you. Points they already earned stay in the family total.")
                    }
                }
            }
            .paperBackground()
            .navigationTitle(member == nil ? "Add Family Member" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Remove \(member?.name ?? "")?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { remove() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let target = member ?? FamilyMember(name: trimmedName, color: color)
        target.name = trimmedName
        target.color = color
        if member == nil { context.insert(target) }
        dismiss()
    }

    private func remove() {
        guard let member else { return }
        for reminder in reminders where reminder.assigneeID == member.memberID {
            reminder.assigneeID = nil
        }
        context.delete(member)
        dismiss()
    }
}
