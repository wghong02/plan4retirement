import CoreData
import Foundation

// MARK: - Account Entity
@objc(AccountEntity)
public class AccountEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var type: String // "Pre-Tax" or "Post-Tax"
    @NSManaged public var currentBalance: Double
    @NSManaged public var annualContribution: Double
    @NSManaged public var expectedROI: Double
    @NSManaged public var contributionIncreaseRate: Double
    @NSManaged public var createdDate: Date
    @NSManaged public var lastUpdatedDate: Date
    @NSManaged public var histories: NSSet?

    func toAccount() -> Account {
        Account(
            id: id,
            name: name,
            type: AccountType(rawValue: type) ?? .preTax,
            currentBalance: currentBalance,
            annualContribution: annualContribution,
            expectedROI: expectedROI,
            contributionIncreaseRate: contributionIncreaseRate,
            createdDate: createdDate,
            lastUpdatedDate: lastUpdatedDate
        )
    }

    static func fromAccount(_ account: Account, context: NSManagedObjectContext) -> AccountEntity {
        let entity = AccountEntity(context: context)
        entity.id = account.id
        entity.name = account.name
        entity.type = account.type.rawValue
        entity.currentBalance = account.currentBalance
        entity.annualContribution = account.annualContribution
        entity.expectedROI = account.expectedROI
        entity.contributionIncreaseRate = account.contributionIncreaseRate
        entity.createdDate = account.createdDate
        entity.lastUpdatedDate = account.lastUpdatedDate
        return entity
    }
}

// MARK: - Account History Entity
@objc(AccountHistoryEntity)
public class AccountHistoryEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var accountId: String
    @NSManaged public var actualBalance: Double
    @NSManaged public var projectedBalance: Double
    @NSManaged public var updateDate: Date
    @NSManaged public var notes: String?

    func toAccountHistory() -> AccountHistory {
        AccountHistory(
            id: id,
            accountId: accountId,
            actualBalance: actualBalance,
            projectedBalance: projectedBalance,
            updateDate: updateDate,
            notes: notes
        )
    }

    static func fromAccountHistory(_ history: AccountHistory, context: NSManagedObjectContext) -> AccountHistoryEntity {
        let entity = AccountHistoryEntity(context: context)
        entity.id = history.id
        entity.accountId = history.accountId
        entity.actualBalance = history.actualBalance
        entity.projectedBalance = history.projectedBalance
        entity.updateDate = history.updateDate
        entity.notes = history.notes
        return entity
    }
}

// MARK: - Projection Snapshot Entity
@objc(ProjectionSnapshotEntity)
public class ProjectionSnapshotEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var projectedRetirementAge: Int32
    @NSManaged public var projectedBalance: Double
    @NSManaged public var projectionData: String // JSON
    @NSManaged public var parametersUsed: String // JSON
    @NSManaged public var createdDate: Date

    func toProjectionSnapshot() -> ProjectionSnapshot? {
        let decoder = JSONDecoder()

        guard let projectionDataJson = projectionData.data(using: .utf8),
              let parametersJson = parametersUsed.data(using: .utf8),
              let dataPoints = try? decoder.decode([ProjectionDataPoint].self, from: projectionDataJson),
              let parameters = try? decoder.decode(ProjectionParameters.self, from: parametersJson) else {
            return nil
        }

        return ProjectionSnapshot(
            id: id,
            name: name,
            projectedRetirementAge: Int(projectedRetirementAge),
            projectedBalance: projectedBalance,
            projectionData: dataPoints,
            parametersUsed: parameters,
            createdDate: createdDate
        )
    }

    static func fromProjectionSnapshot(_ snapshot: ProjectionSnapshot, context: NSManagedObjectContext) -> ProjectionSnapshotEntity? {
        let encoder = JSONEncoder()

        guard let projectionDataJson = try? encoder.encode(snapshot.projectionData),
              let parametersJson = try? encoder.encode(snapshot.parametersUsed),
              let projectionDataString = String(data: projectionDataJson, encoding: .utf8),
              let parametersString = String(data: parametersJson, encoding: .utf8) else {
            return nil
        }

        let entity = ProjectionSnapshotEntity(context: context)
        entity.id = snapshot.id
        entity.name = snapshot.name
        entity.projectedRetirementAge = Int32(snapshot.projectedRetirementAge)
        entity.projectedBalance = snapshot.projectedBalance
        entity.projectionData = projectionDataString
        entity.parametersUsed = parametersString
        entity.createdDate = snapshot.createdDate
        return entity
    }
}

// MARK: - Life Event Entity
@objc(LifeEventEntity)
public class LifeEventEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var eventDate: Date
    @NSManaged public var amount: Double
    @NSManaged public var notes: String?

    func toLifeEvent() -> LifeEvent {
        LifeEvent(
            id: id,
            name: name,
            type: LifeEventType(rawValue: type) ?? .other,
            eventDate: eventDate,
            amount: amount,
            notes: notes
        )
    }

    static func fromLifeEvent(_ event: LifeEvent, context: NSManagedObjectContext) -> LifeEventEntity {
        let entity = LifeEventEntity(context: context)
        entity.id = event.id
        entity.name = event.name
        entity.type = event.type.rawValue
        entity.eventDate = event.eventDate
        entity.amount = event.amount
        entity.notes = event.notes
        return entity
    }
}
