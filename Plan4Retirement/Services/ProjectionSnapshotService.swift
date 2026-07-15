import CoreData
import Foundation

class ProjectionSnapshotService {
    private let context: NSManagedObjectContext
    private var maxSnapshots: Int = 10

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, maxSnapshots: Int = 10) {
        self.context = context
        self.maxSnapshots = maxSnapshots
    }

    func setMaxSnapshots(_ max: Int) {
        self.maxSnapshots = max
    }

    // MARK: - Create
    func saveSnapshot(_ snapshot: ProjectionSnapshot) throws {
        // Check if we're at the limit
        let count = try getSnapshotCount()
        if count >= maxSnapshots {
            try deleteOldestSnapshot()
        }

        guard ProjectionSnapshotEntity.fromProjectionSnapshot(snapshot, context: context) != nil else { return }
        try context.save()
    }

    // MARK: - Read
    func getSnapshot(by id: String) throws -> ProjectionSnapshot? {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        return results.first?.toProjectionSnapshot()
    }

    func getAllSnapshots() throws -> [ProjectionSnapshot] {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectionSnapshotEntity.createdDate, ascending: false)]

        let results = try context.fetch(request)
        return results.compactMap { $0.toProjectionSnapshot() }
    }

    func getSnapshotCount() throws -> Int {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        return try context.count(for: request)
    }

    // MARK: - Update
    func updateSnapshot(_ snapshot: ProjectionSnapshot) throws {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        request.predicate = NSPredicate(format: "id == %@", snapshot.id)

        let results = try context.fetch(request)
        guard let entity = results.first else { return }

        let encoder = JSONEncoder()
        if let projectionDataJson = try? encoder.encode(snapshot.projectionData),
           let projectionDataString = String(data: projectionDataJson, encoding: .utf8) {
            entity.projectionData = projectionDataString
        }
        entity.name = snapshot.name

        try context.save()
    }

    // MARK: - Delete
    func deleteSnapshot(by id: String) throws {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        request.predicate = NSPredicate(format: "id == %@", id)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteOldestSnapshot() throws {
        let request = ProjectionSnapshotEntity.fetchRequest() as! NSFetchRequest<ProjectionSnapshotEntity>
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectionSnapshotEntity.createdDate, ascending: true)]
        request.fetchLimit = 1

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        try context.save()
    }

    func deleteAllSnapshots() throws {
        let request = ProjectionSnapshotEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }
}
