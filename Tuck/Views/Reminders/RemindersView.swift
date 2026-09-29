import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var context
    @Query private var reminders: [Reminder]
    @Query private var members: [FamilyMember]

    @State private var filter: ReminderCategory?
    @State private var isCreating = false
    @State private var editing: Reminder?
    @State private var showCompleted = false

    @State private var showWorkAtHome = false

    private var mode: AppMode? { ModeController.shared.mode }

    /// In Home mode the "All" list leaves out work, unless you ask to see it.
    private var hidesWork: Bool { mode == .home && filter == nil && !showWorkAtHome }

    private var visible: [Reminder] {
        reminders.filter { (filter == nil || $0.category == filter) && (!hidesWork || $0.category != .work) }
    }

    private var hiddenWorkCount: Int {
        hidesWork ? reminders.filter { $0.category == .work && !$0.isDone }.count : 0
    }

    private var open: [Reminder] {
        visible
            .filter { !$0.isDone }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var completed: [Reminder] {
        visible
            .filter(\.isDone)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $filter) {
                        Text("All").tag(ReminderCategory?.none)
                        ForEach(ReminderCategory.allCases) { category in
                            Text(category.label).tag(Optional(category))
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if hiddenWorkCount > 0 {
                    Section {
                        HStack {
                            Label("Home mode: \(hiddenWorkCount) work \(hiddenWorkCount == 1 ? "item" : "items") hidden", systemImage: "house.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Show") { withAnimation { showWorkAtHome = true } }
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .listRowBackground(Theme.card)
                }

                if open.isEmpty {
                    Section {
                        Text("All clear. Tap + to add a reminder.")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Theme.card)
                } else {
                    Section("To do") { rows(open) }
                }

                if !completed.isEmpty {
                    Section(isExpanded: $showCompleted) {
                        rows(completed)
                    } header: {
                        Text("Completed (\(completed.count))")
                    }
                }
            }
            .listStyle(.sidebar)
            .paperBackground()
            .navigationTitle("Reminders")
            .toolbar {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New reminder")
            }
            .sheet(isPresented: $isCreating) { ReminderEditorView(category: filter ?? .personal) }
            .sheet(item: $editing) { reminder in ReminderEditorView(reminder: reminder) }
        }
    }

    @ViewBuilder
    private func rows(_ items: [Reminder]) -> some View {
        ForEach(items) { reminder in
            ReminderRow(reminder: reminder, assignee: members.first { $0.memberID == reminder.assigneeID })
                .contentShape(Rectangle())
                .onTapGesture { editing = reminder }
                .listRowBackground(Theme.card)
                .swipeActions {
                    Button(role: .destructive) {
                        NotificationManager.cancel(reminder)
                        context.delete(reminder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}
