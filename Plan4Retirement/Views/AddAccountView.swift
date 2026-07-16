import SwiftUI

struct AddAccountView: View {
    @Binding var isPresented: Bool
    var onSave: (Account) -> Void

    @State private var name: String = ""
    @State private var selectedType: AccountType = .preTax
    @State private var currentBalance: String = ""
    @State private var annualContribution: String = ""
    @State private var expectedROI: String = "7.0"
    @State private var contributionIncreaseRate: String = "2.0"

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name (e.g., 401k, IRA, Brokerage)", text: $name)

                    Picker("Tax Treatment", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Financial Information") {
                    TextField("Current Balance", text: $currentBalance)
                        .keyboardType(.decimalPad)

                    TextField("Annual Contribution", text: $annualContribution)
                        .keyboardType(.decimalPad)

                    TextField("Expected Annual Growth / ROI (%)", text: $expectedROI)
                        .keyboardType(.decimalPad)

                    TextField("Annual Contribution Increase (%)", text: $contributionIncreaseRate)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !currentBalance.isEmpty && !annualContribution.isEmpty && !expectedROI.isEmpty
    }

    private func saveAccount() {
        let balance = Double(currentBalance) ?? 0
        let contribution = Double(annualContribution) ?? 0
        let roi = Double(expectedROI) ?? 0
        let increase = Double(contributionIncreaseRate) ?? 0

        let account = Account(
            name: name,
            type: selectedType,
            currentBalance: balance,
            annualContribution: contribution,
            expectedROI: roi,
            contributionIncreaseRate: increase
        )

        onSave(account)
        isPresented = false
    }
}

#Preview {
    AddAccountView(isPresented: .constant(true)) { _ in }
}
