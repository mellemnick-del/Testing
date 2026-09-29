import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("closeOutNudgeOn") private var nudgeOn = false
    @AppStorage("closeOutNudgeMinutes") private var nudgeMinutes = 20 * 60 + 30
    @State private var notificationsBlocked = false

    @AppStorage(ModeController.Keys.enabled) private var modesOn = true
    @AppStorage(ModeController.Keys.workStart) private var workStart = 8 * 60
    @AppStorage(ModeController.Keys.workEnd) private var workEnd = 17 * 60 + 30
    @AppStorage(ModeController.Keys.workDays) private var workDays = "2,3,4,5,6"

    /// Shows minutes-after-midnight settings in a time picker.
    private func time(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
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
                        DatePicker("Time", selection: time($nudgeMinutes), displayedComponents: .hourAndMinute)
                    }
                } footer: {
                    Text("A gentle nudge to take two minutes and close out your day.")
                }

                Section {
                    Toggle(isOn: $modesOn.animation()) {
                        Label("Work and home modes", systemImage: "briefcase")
                    }
                    if modesOn {
                        DatePicker("Work starts", selection: time($workStart), displayedComponents: .hourAndMinute)
                        DatePicker("Work ends", selection: time($workEnd), displayedComponents: .hourAndMinute)
                        WeekdayPicker(selection: $workDays)
                    }
                } header: {
                    Text("Work and home")
                } footer: {
                    Text("Outside work hours, Home mode hides work reminders so work stays at work. To switch with your iPhone Focus instead, open Settings, tap Focus, pick a Focus, and add a Tuck filter.")
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
            .onChange(of: modesOn) { ModeController.shared.refresh() }
            .onChange(of: workStart) { ModeController.shared.refresh() }
            .onChange(of: workEnd) { ModeController.shared.refresh() }
            .onChange(of: workDays) { ModeController.shared.refresh() }
            .alert("Notifications are off", isPresented: $notificationsBlocked) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("To get a nightly reminder, allow notifications for Tuck in the Settings app.")
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

/// Seven day toggles, stored as Calendar weekday numbers like "2,3,4,5,6".
private struct WeekdayPicker: View {
    @Binding var selection: String

    private var selected: Set<Int> {
        Set(selection.split(separator: ",").compactMap { Int($0) })
    }

    /// Weekday numbers in the order this locale shows them.
    private var ordered: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack {
            Text("Workdays")
            Spacer()
            HStack(spacing: 6) {
                ForEach(ordered, id: \.self) { day in
                    let on = selected.contains(day)
                    Button {
                        var days = selected
                        if on { days.remove(day) } else { days.insert(day) }
                        selection = days.sorted().map(String.init).joined(separator: ",")
                    } label: {
                        Text(Calendar.current.veryShortWeekdaySymbols[day - 1])
                            .font(.caption.weight(.semibold))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(on ? Theme.accent : Color.secondary.opacity(0.12)))
                            .foregroundStyle(on ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }
}
