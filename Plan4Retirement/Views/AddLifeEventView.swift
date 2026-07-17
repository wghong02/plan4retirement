import SwiftUI

struct AddLifeEventView: View {
    @Binding var isPresented: Bool
    var onSave: (LifeEvent) -> Void

    @State private var name: String = ""
    @State private var selectedType: LifeEventType = .housePurchase
    @State private var eventDate: Date = Date()
    @State private var amount: String = ""
    @State private var notes: String = ""

    // Loan financing.
    @State private var isLoan: Bool = false
    @State private var loanAmount: String = ""
    @State private var loanRate: String = ""
    @State private var loanTermMonths: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $name)

                    Picker("Event Type", selection: $selectedType) {
                        ForEach(LifeEventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                }

                Section("Financial Impact") {
                    if selectedType.supportsLoan {
                        Toggle("Finance with a loan", isOn: $isLoan)
                    }

                    HStack {
                        Text(isLoan ? "Down Payment" : "Amount")
                        Spacer()
                        TextField(isLoan ? "Down Payment" : "Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("USD")
                    }

                    if isLoan {
                        HStack {
                            Text("Loan Amount")
                            Spacer()
                            TextField("Amount Borrowed", text: $loanAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("USD")
                        }

                        HStack {
                            Text("Loan Rate")
                            Spacer()
                            TextField("0", text: $loanRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("%")
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Text("Loan Term")
                            Spacer()
                            TextField("0", text: $loanTermMonths)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text("months")
                                .foregroundColor(.gray)
                        }

                        if let payment = estimatedMonthlyPayment {
                            HStack {
                                Text("Est. Monthly Payment")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(payment.formatted(as: true))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedType) { newValue in
                // A loan only makes sense for expense-type events.
                if !newValue.supportsLoan { isLoan = false }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    /// Live payment preview from the current inputs, or nil when they're incomplete.
    private var estimatedMonthlyPayment: Double? {
        guard isLoan,
              let principal = Double(loanAmount), principal > 0,
              let rate = Double(loanRate),
              let term = Int(loanTermMonths), term > 0 else { return nil }
        return LifeEvent.monthlyPayment(principal: principal, annualRatePercent: rate, termMonths: term)
    }

    private var isFormValid: Bool {
        guard !name.isEmpty, !amount.isEmpty, Double(amount) != nil else { return false }
        if isLoan {
            guard let principal = Double(loanAmount), principal > 0,
                  Double(loanRate) != nil,
                  let term = Int(loanTermMonths), term > 0 else { return false }
        }
        return true
    }

    private func saveEvent() {
        let financed = isLoan && selectedType.supportsLoan
        let event = LifeEvent(
            name: name,
            type: selectedType,
            eventDate: eventDate,
            amount: Double(amount) ?? 0,
            notes: notes.isEmpty ? nil : notes,
            isLoan: financed,
            loanAmount: financed ? (Double(loanAmount) ?? 0) : 0,
            loanRate: financed ? (Double(loanRate) ?? 0) : 0,
            loanTermMonths: financed ? (Int(loanTermMonths) ?? 0) : 0
        )

        onSave(event)
        isPresented = false
    }
}

#Preview {
    AddLifeEventView(isPresented: .constant(true)) { _ in }
}
