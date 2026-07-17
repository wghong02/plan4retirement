import CoreData
import Foundation

class AccountHistoryService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Create
    func addHistoryEntry(_ entry: AccountHistory) throws {
        let entity = AccountHistoryEntity.fromAccountHistory(entry, context: context)
        try context.save()
    }

    // MARK: - Read
    func getHistoryForAccount(accountId: String) throws -> [AccountHistory] {
        let request = AccountHistoryEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "accountId == %@", accountId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AccountHistoryEntity.updateDate, ascending: false)]

        let results = try context.fetch(request)
        return results.map { $0.toAccountHistory() }
    }

    func getLatestHistoryEntry(for accountId: String) throws -> AccountHistory? {
        let request = AccountHistoryEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "accountId == %@", accountId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AccountHistoryEntity.updateDate, ascending: false)]
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first?.toAccountHistory()
    }

    /// True when another entry for the account has the same balance, calendar day,
    /// and note. Pass `excludingId` when editing so an entry doesn't match itself.
    func hasDuplicateEntry(accountId: String, balance: Double, date: Date, notes: String?, excludingId: String? = nil) throws -> Bool {
        let entries = try getHistoryForAccount(accountId: accountId)
        return entries.contains { entry in
            entry.id != excludingId
                && entry.actualBalance == balance
                && Calendar.current.isDate(entry.updateDate, inSameDayAs: date)
                && (entry.notes ?? "") == (notes ?? "")
        }
    }

    // MARK: - Update
    func updateHistoryEntry(_ entry: AccountHistory) throws {
        let request = AccountHistoryEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id)

        let results = try context.fetch(request)
        guard let entity = results.first else { return }

        entity.actualBalance = entry.actualBalance
        entity.projectedBalance = entry.projectedBalance
        entity.updateDate = entry.updateDate
        entity.notes = entry.notes

        try context.save()
    }

    // MARK: - Delete
    func deleteHistoryEntry(by id: String) throws {
        let request = AccountHistoryEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteHistoryForAccount(accountId: String) throws {
        let request = AccountHistoryEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "accountId == %@", accountId)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()
    }
}
