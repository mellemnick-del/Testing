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

    private var visible: [Reminder] {
        reminders.filter { filter == nil || $0.category == filter }
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
