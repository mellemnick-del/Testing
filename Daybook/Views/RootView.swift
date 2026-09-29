import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            JournalListView()
                .tabItem { Label("Journal", systemImage: "book.closed") }
            NotesListView()
                .tabItem { Label("Notes", systemImage: "note.text") }
            RemindersView()
                .tabItem { Label("Reminders", systemImage: "checklist") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
