import SwiftUI

/// Edits an account's details (name, tax treatment, growth/ROI, contribution increase).
/// Balance changes are handled separately by `UpdateBalanceView`.
struct UpdateDetailsView: View {
    let account: Account
    @Binding var isPresented: Bool
    var onSave: (Account) -> Void

    @State private var name: String
    @State private var type: AccountType
    @State private var annualContribution: String
    @State private var roi: String
    @State private var contributionIncrease: String

    init(
        account: Account,
        isPresented: Binding<Bool>,
        onSave: @escaping (Account) -> Void
    ) {
        self.account = account
        self._isPresented = isPresented
        self.onSave = onSave
        _name = State(initialValue: account.name)
        _type = State(initialValue: account.type)
        _annualContribution = State(initialValue: account.annualContribution.fieldText)
        _roi = State(initialValue: account.expectedROI.fieldText)
        _contributionIncrease = State(initialValue: account.contributionIncreaseRate.fieldText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Account Name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Tax Treatment", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    HStack {
                        Text("Annual Contribution")
                        Spacer()
                        TextField("0", text: $annualContribution)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Expected Growth / ROI")
                        Spacer()
                        TextField("0", text: $roi)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("%")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Contribution Increase")
                        Spacer()
                        TextField("0", text: $contributionIncrease)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("%")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Update Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        var updated = account
        updated.name = name
        updated.type = type
        updated.annualContribution = Double(annualContribution) ?? account.annualContribution
        updated.expectedROI = Double(roi) ?? account.expectedROI
        updated.contributionIncreaseRate = Double(contributionIncrease) ?? account.contributionIncreaseRate

        onSave(updated)
        isPresented = false
    }
}

#Preview {
    UpdateDetailsView(
        account: Account(
            name: "401(k)",
            type: .preTax,
            currentBalance: 100000,
            annualContribution: 10000,
            expectedROI: 7.0
        ),
        isPresented: .constant(true)
    ) { _ in }
}
