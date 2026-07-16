import CoreData
import Foundation

class AccountService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Create
    func addAccount(_ account: Account) throws {
        _ = AccountEntity.fromAccount(account, context: context)
        try context.save()
    }

    // MARK: - Read
    func getAccount(by id: String) throws -> Account? {
        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        return results.first?.toAccount()
    }

    func getAllAccounts() throws -> [Account] {
        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AccountEntity.createdDate, ascending: true)]

        let results = try context.fetch(request)
        return results.map { $0.toAccount() }
    }

    func getAccountCount() throws -> Int {
        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        return try context.count(for: request)
    }

    // MARK: - Update
    func updateAccount(_ account: Account) throws {
        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        request.predicate = NSPredicate(format: "id == %@", account.id)

        let results = try context.fetch(request)
        guard let entity = results.first else { return }

        entity.name = account.name
        entity.type = account.type.rawValue
        entity.currentBalance = account.currentBalance
        entity.annualContribution = account.annualContribution
        entity.expectedROI = account.expectedROI
        entity.contributionIncreaseRate = account.contributionIncreaseRate
        entity.lastUpdatedDate = Date()

        try context.save()
    }

    /// Sets the account's current balance to its most recent (latest-dated) history
    /// entry. If there is no history, the balance is left unchanged.
    func syncCurrentBalanceFromHistory(accountId: String) throws {
        let historyService = AccountHistoryService(context: context)
        guard let latest = try historyService.getLatestHistoryEntry(for: accountId) else { return }

        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        request.predicate = NSPredicate(format: "id == %@", accountId)

        let results = try context.fetch(request)
        guard let entity = results.first else { return }

        entity.currentBalance = latest.actualBalance
        entity.lastUpdatedDate = Date()

        try context.save()
    }

    // MARK: - Delete
    func deleteAccount(by id: String) throws {
        let request = AccountEntity.fetchRequest() as! NSFetchRequest<AccountEntity>
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()

        // Also delete associated history
        let historyService = AccountHistoryService(context: context)
        try historyService.deleteHistoryForAccount(accountId: id)
    }

    func deleteAllAccounts() throws {
        let request = AccountEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }
}
