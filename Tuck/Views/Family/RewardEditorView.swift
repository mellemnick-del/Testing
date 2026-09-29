import SwiftUI
import SwiftData

struct RewardEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.createdAt) private var members: [FamilyMember]

    private let reward: Reward?
    @State private var title: String
    @State private var cost: Int
    @State private var memberID: String?

    private static let presets = [25, 50, 100, 200]
    private static let ideas = ["Pizza night", "Pick Friday's movie", "Extra screen time", "Ice cream trip", "Stay up 30 minutes late"]

    init(reward: Reward? = nil) {
        self.reward = reward
        _title = State(initialValue: reward?.title ?? "")
        _cost = State(initialValue: reward?.cost ?? 50)
        _memberID = State(initialValue: reward?.memberID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Reward", text: $title)
                        .font(Theme.serif(.title3))
                    if reward == nil && title.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Self.ideas, id: \.self) { idea in
                                    Button(idea) { title = idea }
                                        .buttonStyle(.bordered)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }

                Section("Points needed") {
                    Stepper(value: $cost, in: 5...2000, step: 5) {
                        Text("\(cost) points").monospacedDigit()
                    }
                    Picker("Quick pick", selection: $cost) {
                        ForEach(Self.presets, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Who's earning it", selection: $memberID) {
                        Text("Whole family").tag(String?.none)
                        ForEach(members) { member in
                            Text(member.name).tag(Optional(member.memberID))
                        }
                    }
                } footer: {
                    Text("Counts points earned from now on. Whole family rewards count everyone's points, including yours.")
                }

                if let reward {
                    Section {
                        Button("Delete reward", role: .destructive) {
                            context.delete(reward)
                            dismiss()
                        }
                    }
                }
            }
            .paperBackground()
            .navigationTitle(reward == nil ? "New Reward" : "Edit Reward")
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
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let reward {
            reward.title = trimmed
            reward.cost = cost
            reward.memberID = memberID
        } else {
            context.insert(Reward(title: trimmed, cost: cost, memberID: memberID))
        }
        dismiss()
    }
}
