import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var showResetConfirmation = false
    @State private var showDeleteDataConfirmation = false

    private let accountService = AccountService()
    private let snapshotService = ProjectionSnapshotService()
    private let historyService = AccountHistoryService()
    private let lifeEventService = LifeEventService()

    var body: some View {
        NavigationStack {
            Form {
                Section("App Settings") {
                    Stepper(
                        "Max Saved Projections: \(settings.maxProjectionSnapshots)",
                        value: $settings.maxProjectionSnapshots,
                        in: 1...50
                    )
                }

                Section("Graph Display") {
                    Stepper(
                        "Months Shown (Monthly): \(settings.maxMonthsDisplayed)",
                        value: $settings.maxMonthsDisplayed,
                        in: 10...200,
                        step: 10
                    )

                    Stepper(
                        "Years Shown (Yearly): \(settings.maxYearsDisplayed)",
                        value: $settings.maxYearsDisplayed,
                        in: 10...200,
                        step: 10
                    )
                }

                Section("Database") {
                    Button(action: { showResetConfirmation = true }) {
                        Label("Reset to Default Settings", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }

                    Button(action: { showDeleteDataConfirmation = true }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset Settings?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset all assumptions and parameters to their default values.")
            }
            .alert("Delete All Data?", isPresented: $showDeleteDataConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all accounts, history, and projections. This action cannot be undone.")
            }
        }
    }

    private func deleteAllData() {
        do {
            try accountService.deleteAllAccounts()
            try snapshotService.deleteAllSnapshots()
            try lifeEventService.deleteAllLifeEvents()
            settings.resetToDefaults()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService.shared)
}
