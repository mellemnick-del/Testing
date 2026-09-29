import SwiftUI

struct RootView: View {
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppRouter.Tab.today)
            JournalListView()
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(AppRouter.Tab.journal)
            NotesListView()
                .tabItem { Label("Notes", systemImage: "note.text") }
                .tag(AppRouter.Tab.notes)
            RemindersView()
                .tabItem { Label("Reminders", systemImage: "checklist") }
                .tag(AppRouter.Tab.reminders)
            FamilyView()
                .tabItem { Label("Family", systemImage: "house") }
                .tag(AppRouter.Tab.family)
        }
        .environment(router)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
