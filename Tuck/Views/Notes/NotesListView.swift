import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var search = ""
    @State private var editing: Note?
    @State private var isCreating = false

    private var filtered: [Note] {
        guard !search.isEmpty else { return notes }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(search) || $0.body.localizedCaseInsensitiveContains(search)
        }
    }

    private var pinned: [Note] { filtered.filter(\.isPinned) }
    private var others: [Note] { filtered.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    EmptyStateView(
                        symbol: "note.text",
                        title: "No notes yet",
                        message: "Grocery lists, meeting takeaways, school pickup codes. Put it all here."
                    )
                } else {
                    List {
                        if !pinned.isEmpty {
                            Section("Pinned") { rows(pinned) }
                        }
                        Section(pinned.isEmpty ? "" : "Notes") { rows(others) }
                    }
                    .searchable(text: $search, prompt: "Search notes")
                }
            }
            .paperBackground()
            .navigationTitle("Notes")
            .toolbar {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New note")
            }
            .sheet(isPresented: $isCreating) { NoteEditorView() }
            .sheet(item: $editing) { note in NoteEditorView(note: note) }
        }
    }

    @ViewBuilder
    private func rows(_ items: [Note]) -> some View {
        ForEach(items) { note in
            Button {
                editing = note
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.displayTitle)
                        .font(Theme.serif(.headline))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(note.updatedAt.formatted(.relative(presentation: .named)))
                        if !note.body.isEmpty {
                            Text(note.body.replacingOccurrences(of: "\n", with: " "))
                                .lineLimit(1)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.card)
            .swipeActions(edge: .leading) {
                Button {
                    withAnimation { note.isPinned.toggle() }
                } label: {
                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                }
                .tint(Theme.accent)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    context.delete(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
