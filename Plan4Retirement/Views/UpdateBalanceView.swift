import SwiftUI

struct UpdateBalanceView: View {
    let account: Account
    @Binding var isPresented: Bool
    var onSave: (Double, String?) -> Void

    @State private var actualBalance: String = ""
    @State private var notes: String = ""

    private let maxNotesLength = 150

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

                    if notes.count > maxNotesLength {
                        Text("Notes must be \(maxNotesLength) characters or fewer (\(notes.count)/\(maxNotesLength))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
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
                    .disabled(actualBalance.isEmpty || notes.count > maxNotesLength)
                }
            }
        }
    }

    private func saveUpdate() {
        if let balance = Double(actualBalance) {
            onSave(balance, notes.isEmpty ? nil : notes)
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
    ) { _, _ in }
}
