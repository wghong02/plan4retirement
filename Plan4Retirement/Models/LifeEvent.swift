import Foundation

struct LifeEvent: Identifiable, Codable {
    let id: String
    var name: String
    var type: LifeEventType
    var eventDate: Date
    /// The full cost of the event, or the down payment when `isLoan` is true.
    var amount: Double
    var notes: String?

    // Loan financing. Only meaningful when `isLoan` is true; `amount` then acts as
    // the down payment and `loanAmount` is the borrowed principal repaid monthly.
    var isLoan: Bool
    var loanAmount: Double     // borrowed principal
    var loanRate: Double       // annual interest rate, percent (e.g. 6.0 for 6%)
    var loanTermMonths: Int

    enum CodingKeys: String, CodingKey {
        case id, name, type, eventDate, amount, notes
        case isLoan, loanAmount, loanRate, loanTermMonths
    }

    init(
        name: String,
        type: LifeEventType,
        eventDate: Date,
        amount: Double,
        notes: String? = nil,
        isLoan: Bool = false,
        loanAmount: Double = 0,
        loanRate: Double = 0,
        loanTermMonths: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.eventDate = eventDate
        self.amount = amount
        self.notes = notes
        self.isLoan = isLoan
        self.loanAmount = loanAmount
        self.loanRate = loanRate
        self.loanTermMonths = loanTermMonths
    }

    /// Full initializer used when hydrating from storage, preserving the stored id.
    init(
        id: String,
        name: String,
        type: LifeEventType,
        eventDate: Date,
        amount: Double,
        notes: String?,
        isLoan: Bool = false,
        loanAmount: Double = 0,
        loanRate: Double = 0,
        loanTermMonths: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.eventDate = eventDate
        self.amount = amount
        self.notes = notes
        self.isLoan = isLoan
        self.loanAmount = loanAmount
        self.loanRate = loanRate
        self.loanTermMonths = loanTermMonths
    }

    /// Custom decoder so snapshots saved before the loan fields existed still decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(LifeEventType.self, forKey: .type)
        eventDate = try container.decode(Date.self, forKey: .eventDate)
        amount = try container.decode(Double.self, forKey: .amount)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isLoan = try container.decodeIfPresent(Bool.self, forKey: .isLoan) ?? false
        loanAmount = try container.decodeIfPresent(Double.self, forKey: .loanAmount) ?? 0
        loanRate = try container.decodeIfPresent(Double.self, forKey: .loanRate) ?? 0
        loanTermMonths = try container.decodeIfPresent(Int.self, forKey: .loanTermMonths) ?? 0
    }

    /// Amortized monthly payment for this event's loan, or 0 when it isn't a loan.
    var monthlyLoanPayment: Double {
        guard isLoan else { return 0 }
        return Self.monthlyPayment(principal: loanAmount, annualRatePercent: loanRate, termMonths: loanTermMonths)
    }

    /// Standard fixed-rate amortized payment. Returns 0 for a non-positive
    /// principal or term; splits evenly when the rate is zero.
    static func monthlyPayment(principal: Double, annualRatePercent: Double, termMonths: Int) -> Double {
        guard principal > 0, termMonths > 0 else { return 0 }
        let monthlyRate = annualRatePercent / 100.0 / 12.0
        guard monthlyRate != 0 else { return principal / Double(termMonths) }
        let factor = pow(1 + monthlyRate, Double(termMonths))
        return principal * monthlyRate * factor / (factor - 1)
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

    /// Loan financing is offered only for expense-type events (not inheritance/other).
    var supportsLoan: Bool {
        switch self {
        case .housePurchase, .carPurchase, .majorExpense, .medicalExpense:
            return true
        case .inheritance, .other:
            return false
        }
    }
}
