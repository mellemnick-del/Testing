import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { ModeController.shared.refresh() }
        }
        .task {
            // Catch the switch at the start and end of the workday.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                ModeController.shared.refresh()
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
