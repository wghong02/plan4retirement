import CoreData
import Foundation

class LifeEventService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Create
    func addLifeEvent(_ event: LifeEvent) throws {
        _ = LifeEventEntity.fromLifeEvent(event, context: context)
        try context.save()
    }

    // MARK: - Read
    func getAllLifeEvents() throws -> [LifeEvent] {
        let request = LifeEventEntity.typedFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LifeEventEntity.eventDate, ascending: true)]

        let results = try context.fetch(request)
        return results.map { $0.toLifeEvent() }
    }

    // MARK: - Delete
    func deleteLifeEvent(by id: String) throws {
        let request = LifeEventEntity.typedFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteAllLifeEvents() throws {
        let request = LifeEventEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }
}
