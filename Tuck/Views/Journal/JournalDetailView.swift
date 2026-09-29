import SwiftUI

struct JournalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry

    @State private var isEditing = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(entry.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.mood.emoji) \(entry.mood.label)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                }
                Text(entry.displayTitle)
                    .font(Theme.serif(.largeTitle, weight: .semibold))
                Text(entry.body)
                    .font(Theme.serif(.body))
                    .lineSpacing(6)
                    .textSelection(.enabled)

                if entry.isCloseOut {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Done that day")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(entry.points) points")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Theme.accent)
                        }
                        if entry.doneItems.isEmpty {
                            Text("A rest day.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(entry.doneItems.enumerated()), id: \.offset) { _, item in
                                Label {
                                    Text(item)
                                } icon: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                    .card()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: "\(entry.displayTitle)\n\n\(entry.body)")
                Menu {
                    Button("Edit", systemImage: "pencil") { isEditing = true }
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            JournalEditorView(entry: entry)
        }
        .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(entry)
                dismiss()
            }
        }
    }
}
