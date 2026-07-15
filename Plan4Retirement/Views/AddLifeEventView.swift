import SwiftUI

struct AddLifeEventView: View {
    @Binding var isPresented: Bool
    var onSave: (LifeEvent) -> Void

    @State private var name: String = ""
    @State private var selectedType: LifeEventType = .housePurchase
    @State private var eventDate: Date = Date()
    @State private var amount: String = ""
    @State private var notes: String = ""

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
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("USD")
                    }

                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Life Event")
            .navigationBarTitleDisplayMode(.inline)
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

    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && Double(amount) != nil
    }

    private func saveEvent() {
        let event = LifeEvent(
            name: name,
            type: selectedType,
            eventDate: eventDate,
            amount: Double(amount) ?? 0,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(event)
        isPresented = false
    }
}

#Preview {
    AddLifeEventView(isPresented: .constant(true)) { _ in }
}
