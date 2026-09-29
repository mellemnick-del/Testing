import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("closeOutNudgeOn") private var nudgeOn = false
    @AppStorage("closeOutNudgeMinutes") private var nudgeMinutes = 20 * 60 + 30
    @State private var notificationsBlocked = false

    private var nudgeTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: nudgeMinutes / 60, minute: nudgeMinutes % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            nudgeMinutes = (parts.hour ?? 20) * 60 + (parts.minute ?? 30)
        }
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $nudgeOn.animation()) {
                        Label("Nightly close-out reminder", systemImage: "moon.stars")
                    }
                    if nudgeOn {
                        DatePicker("Time", selection: nudgeTime, displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text("A gentle nudge to take two minutes and close out your day.")
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    Label("Everything stays on this iPhone. No accounts, no tracking.", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .paperBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: nudgeOn) { applyNudge() }
            .onChange(of: nudgeMinutes) { applyNudge() }
            .alert("Notifications are off", isPresented: $notificationsBlocked) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("To get a nightly reminder, allow notifications for Daybook in the Settings app.")
            }
        }
    }

    private func applyNudge() {
        guard nudgeOn else {
            NotificationManager.cancelCloseOutNudge()
            return
        }
        Task {
            let allowed = await NotificationManager.scheduleCloseOutNudge(minutesAfterMidnight: nudgeMinutes)
            if !allowed {
                nudgeOn = false
                notificationsBlocked = true
            }
        }
    }
}

#Preview {
    SettingsView()
}
