import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsService
    @State private var showResetConfirmation = false
    @State private var showDeleteDataConfirmation = false

    // Editing buffers, cached to `settings` automatically as they change.
    @State private var snapshotsText = ""
    @State private var monthsText = ""
    @State private var yearsText = ""

    @FocusState private var inputActive: Bool

    private let accountService = AccountService()
    private let snapshotService = ProjectionSnapshotService()
    private let historyService = AccountHistoryService()
    private let lifeEventService = LifeEventService()

    var body: some View {
        NavigationStack {
            Form {
                Section("App Settings") {
                    StepperField(
                        title: "Max Saved Projections",
                        text: $snapshotsText,
                        range: 1...50,
                        focus: $inputActive,
                        isValid: snapshots != nil,
                        errorMessage: "Please enter a number between 1 and 50"
                    )
                    .onChange(of: snapshotsText) { _ in commit() }
                }

                Section("Graph Display") {
                    StepperField(
                        title: "Points Shown (Monthly)",
                        text: $monthsText,
                        range: 10...200,
                        focus: $inputActive,
                        isValid: months != nil,
                        errorMessage: "Please enter a number between 10 and 200"
                    )
                    .onChange(of: monthsText) { _ in commit() }

                    StepperField(
                        title: "Points Shown (Yearly)",
                        text: $yearsText,
                        range: 10...200,
                        focus: $inputActive,
                        isValid: years != nil,
                        errorMessage: "Please enter a number between 10 and 200"
                    )
                    .onChange(of: yearsText) { _ in commit() }

                    Toggle("Show in Today's Dollars", isOn: $settings.showInflationAdjusted)
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: { inputActive = false }) {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .onAppear(perform: loadFromSettings)
            .alert("Reset Settings?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                    loadFromSettings()
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

    // MARK: - Validation
    private var snapshots: Int? { validInt(snapshotsText, in: 1...50) }
    private var months: Int? { validInt(monthsText, in: 10...200) }
    private var years: Int? { validInt(yearsText, in: 10...200) }

    private func validInt(_ text: String, in range: ClosedRange<Int>) -> Int? {
        guard let value = Int(text), range.contains(value) else { return nil }
        return value
    }

    // MARK: - Load / Auto-save
    private func loadFromSettings() {
        snapshotsText = "\(settings.maxProjectionSnapshots)"
        monthsText = "\(settings.maxMonthsDisplayed)"
        yearsText = "\(settings.maxYearsDisplayed)"
    }

    private func commit() {
        if let snapshots { settings.maxProjectionSnapshots = snapshots }
        if let months { settings.maxMonthsDisplayed = months }
        if let years { settings.maxYearsDisplayed = years }
    }

    private func deleteAllData() {
        do {
            try accountService.deleteAllAccounts()
            try snapshotService.deleteAllSnapshots()
            try lifeEventService.deleteAllLifeEvents()
            settings.resetToDefaults()
            loadFromSettings()
        } catch {
            AppLog.error("Error deleting data: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsService.shared)
}
