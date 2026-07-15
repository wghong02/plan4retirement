import Foundation

struct LifeEvent: Identifiable, Codable {
    let id: String
    var name: String
    var type: LifeEventType
    var eventDate: Date
    var amount: Double
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type, eventDate, amount, notes
    }

    init(
        name: String,
        type: LifeEventType,
        eventDate: Date,
        amount: Double,
        notes: String? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.eventDate = eventDate
        self.amount = amount
        self.notes = notes
    }

    /// Full initializer used when hydrating from storage, preserving the stored id.
    init(
        id: String,
        name: String,
        type: LifeEventType,
        eventDate: Date,
        amount: Double,
        notes: String?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.eventDate = eventDate
        self.amount = amount
        self.notes = notes
    }
}

enum LifeEventType: String, Codable, CaseIterable {
    case housePurchase = "House Purchase"
    case carPurchase = "Car Purchase"
    case majorExpense = "Major Expense"
    case inheritance = "Inheritance"
    case medicalExpense = "Medical Expense"
    case other = "Other"

    var displayName: String {
        self.rawValue
    }
}
