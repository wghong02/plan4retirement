import SwiftUI

struct UpdateBalanceView: View {
    let account: Account
    /// When set, the view edits an existing history entry instead of adding a new one.
    var existingEntry: AccountHistory?
    @Binding var isPresented: Bool
    var onSave: (Double, Date, String?) -> Void
    /// When provided (edit mode, and deletion allowed), shows a Delete button.
    var onDelete: (() -> Void)?

    @State private var actualBalance: String
    @State private var notes: String
    @State private var date: Date

    private let maxNotesLength = 150

    init(
        account: Account,
        existingEntry: AccountHistory? = nil,
        isPresented: Binding<Bool>,
        onSave: @escaping (Double, Date, String?) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.account = account
        self.existingEntry = existingEntry
        self._isPresented = isPresented
        self.onSave = onSave
        self.onDelete = onDelete
        _actualBalance = State(initialValue: existingEntry.map { Self.balanceString($0.actualBalance) } ?? "")
        _notes = State(initialValue: existingEntry?.notes ?? "")
        _date = State(initialValue: existingEntry?.updateDate ?? Date())
    }

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

                Section(existingEntry == nil ? "Update" : "Edit") {
                    TextField("New Actual Balance", text: $actualBalance)
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Notes (optional)", text: $notes)

                    if notes.count > maxNotesLength {
                        Text("Notes must be \(maxNotesLength) characters or fewer (\(notes.count)/\(maxNotesLength))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete", systemImage: "trash")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingEntry == nil ? "Update Balance" : "Edit Balance")
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
            // Store the calendar day only (no time-of-day component).
            onSave(balance, Calendar.current.startOfDay(for: date), notes.isEmpty ? nil : notes)
            isPresented = false
        }
    }

    /// Whole numbers show without a trailing ".0" when pre-filling for editing.
    private static func balanceString(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
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
    ) { _, _, _ in }
}
