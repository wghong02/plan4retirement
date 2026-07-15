import SwiftUI

struct UpdateBalanceView: View {
    let account: Account
    @Binding var isPresented: Bool
    var onSave: (Double) -> Void

    @State private var actualBalance: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text(account.name)
                        .foregroundColor(.gray)

                    Text("Tax Treatment: \(account.type.displayName)")
                        .foregroundColor(.gray)

                    Text("Current Balance: \(account.currentBalance.formatted(as: true))")
                        .foregroundColor(.gray)
                }

                Section("Update") {
                    TextField("New Actual Balance", text: $actualBalance)
                        .keyboardType(.decimalPad)

                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Update Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUpdate()
                    }
                    .disabled(actualBalance.isEmpty)
                }
            }
        }
    }

    private func saveUpdate() {
        if let balance = Double(actualBalance) {
            onSave(balance)
            isPresented = false
        }
    }
}

#Preview {
    UpdateBalanceView(
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
