import Foundation

struct AccountHistory: Identifiable, Codable {
    let id: String
    let accountId: String
    var actualBalance: Double
    var projectedBalance: Double
    var updateDate: Date
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, accountId, actualBalance, projectedBalance, updateDate, notes
    }

    init(
        accountId: String,
        actualBalance: Double,
        projectedBalance: Double,
        updateDate: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID().uuidString
        self.accountId = accountId
        self.actualBalance = actualBalance
        self.projectedBalance = projectedBalance
        self.updateDate = updateDate
        self.notes = notes
    }

    /// Full initializer used when hydrating from storage, preserving the stored id.
    init(
        id: String,
        accountId: String,
        actualBalance: Double,
        projectedBalance: Double,
        updateDate: Date,
        notes: String?
    ) {
        self.id = id
        self.accountId = accountId
        self.actualBalance = actualBalance
        self.projectedBalance = projectedBalance
        self.updateDate = updateDate
        self.notes = notes
    }
}
