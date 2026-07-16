import Foundation

struct Account: Identifiable, Codable {
    let id: String
    var name: String
    var type: AccountType
    var currentBalance: Double
    var annualContribution: Double
    var expectedROI: Double // Annual growth as percentage (e.g., 7.0 for 7%)
    var contributionIncreaseRate: Double // Annual raise applied to contributions (e.g., 2.0 for 2%)
    let createdDate: Date
    var lastUpdatedDate: Date

    enum CodingKeys: String, CodingKey {
        case id, name, type, currentBalance, annualContribution, expectedROI, contributionIncreaseRate, createdDate, lastUpdatedDate
    }

    init(
        name: String,
        type: AccountType,
        currentBalance: Double,
        annualContribution: Double,
        expectedROI: Double,
        contributionIncreaseRate: Double = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.currentBalance = currentBalance
        self.annualContribution = annualContribution
        self.expectedROI = expectedROI
        self.contributionIncreaseRate = contributionIncreaseRate
        self.createdDate = Date()
        self.lastUpdatedDate = Date()
    }

    /// Full initializer used when hydrating from storage, preserving the stored id and dates.
    init(
        id: String,
        name: String,
        type: AccountType,
        currentBalance: Double,
        annualContribution: Double,
        expectedROI: Double,
        contributionIncreaseRate: Double,
        createdDate: Date,
        lastUpdatedDate: Date
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currentBalance = currentBalance
        self.annualContribution = annualContribution
        self.expectedROI = expectedROI
        self.contributionIncreaseRate = contributionIncreaseRate
        self.createdDate = createdDate
        self.lastUpdatedDate = lastUpdatedDate
    }
}

enum AccountType: String, Codable, CaseIterable {
    case preTax = "Pre-Tax"
    case postTax = "Post-Tax"

    var displayName: String {
        self.rawValue
    }
}

extension Array where Element == Account {
    /// Combined current balance across all accounts.
    var totalBalance: Double {
        reduce(0) { $0 + $1.currentBalance }
    }
}
