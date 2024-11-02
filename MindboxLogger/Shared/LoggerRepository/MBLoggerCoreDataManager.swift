//
//  MBLoggerCoreDataManager.swift
//  MindboxLogger
//
//  Created by Akylbek Utekeshev on 06.02.2023.
//  Copyright © 2023 Mikhail Barilov. All rights reserved.
//

import Foundation
import CoreData
import OSLog

public class MBLoggerCoreDataManager {
    public static let shared = MBLoggerCoreDataManager()

//    static let pointsOfInterests = OSLog(subsystem: "com.smk.Example", category: .pointsOfInterest)

    @available(iOS 15.0, *)
    static let signposter = OSSignposter()

    @available(iOS 15.0, *)
    static let signposterFlushBuffer = OSSignposter()

    private enum Constants {
        static let model = "CDLogMessage"
        static let dbSizeLimitKB: Int = 10_000
        static let operationLimitBeforeNeedToDelete = 20
//        static let batchSize = 10
    }

    private var logQueue: [LogMessage] = []
    private var isWriting = false

    private let queue = DispatchQueue(label: "com.Mindbox.loggerManager", qos: .utility)
    private var persistentStoreDescription: NSPersistentStoreDescription?
    private var writeCount = 0 {
        didSet {
            if writeCount > Constants.operationLimitBeforeNeedToDelete {
                writeCount = 0
            }
        }
    }

    lazy var persistentContainer: MBPersistentContainer = {
        MBPersistentContainer.applicationGroupIdentifier = MBLoggerUtilitiesFetcher().applicationGroupIdentifier

        #if SWIFT_PACKAGE
        guard let bundleURL = Bundle.module.url(forResource: Constants.model, withExtension: "momd"),
              let mom = NSManagedObjectModel(contentsOf: bundleURL) else {
            fatalError("Failed to initialize NSManagedObjectModel for \(Constants.model)")
        }
        let container = MBPersistentContainer(name: Constants.model, managedObjectModel: mom)
        #else
        let podBundle = Bundle(for: MBLoggerCoreDataManager.self)
        let container: MBPersistentContainer
        if let url = podBundle.url(forResource: "MindboxLogger", withExtension: "bundle"),
           let bundle = Bundle(url: url),
           let modelURL = bundle.url(forResource: Constants.model, withExtension: "momd"),
           let mom = NSManagedObjectModel(contentsOf: modelURL) {
            container = MBPersistentContainer(name: Constants.model, managedObjectModel: mom)
        } else {
            container = MBPersistentContainer(name: Constants.model)
        }
        #endif

        let storeURL = FileManager.storeURL(for: MBLoggerUtilitiesFetcher().applicationGroupIdentifier, databaseName: Constants.model)

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(FileProtectionType.none as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        storeDescription.setValue("DELETE" as NSObject, forPragmaNamed: "journal_mode") // Disabling WAL journal
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }

        return container
    }()

    private lazy var context: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        return context
    }()

    // MARK: - CRUD Operations
    public func create(message: String, timestamp: Date, completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logQueue.append(LogMessage(timestamp: timestamp, message: message))

            if !self.isWriting {
                self.writeNextBatch()
            }

            completion?()
        }
    }

    private func writeNextBatch() {
        guard !logQueue.isEmpty else { return }

        isWriting = true
        let logsToWrite = logQueue
        logQueue.removeAll()

        if #available(iOS 13.0, *) {
            performBatchInsert(logs: logsToWrite)
        } else {
            performContextInsertion(logs: logsToWrite)
        }
    }

    @available(iOS 13.0, *)
    private func performBatchInsert(logs: [LogMessage]) {
        print(#function)
        print(logs.count)
        let insertData = logs.map { ["message": $0.message, "timestamp": $0.timestamp] }
        let insertRequest = NSBatchInsertRequest(entityName: Constants.model, objects: insertData)

        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                try self.context.execute(insertRequest)
                self.finishWriting()
            } catch {
                print("Failed to batch insert logs: \(error)")
                self.finishWriting()
            }
        }
    }

    private func performContextInsertion(logs: [LogMessage]) {
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                for log in logs {
                    let entity = CDLogMessage(context: self.context)
                    entity.message = log.message
                    entity.timestamp = log.timestamp
                }
                try self.saveEvent(withContext: self.context)
                self.finishWriting()
            } catch {
                print("Failed to flush logs: \(error)")
                self.finishWriting()
            }
        }
    }

    private func finishWriting() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.isWriting = false
            self.checkDatabaseSizeAndDeleteIfNeeded()
            if !self.logQueue.isEmpty {
                self.writeNextBatch()
            }
        }
    }

    private func checkDatabaseSizeAndDeleteIfNeeded() {
        if getDBFileSize() > Constants.dbSizeLimitKB {
            do {
                try delete()
            } catch {
                print("Failed to delete logs: \(error)")
            }
        }
    }

    public func getFirstLog() throws -> LogMessage? {
        var fetchedLogMessage: LogMessage?
        try context.executePerformAndWait {
            let fetchRequest = NSFetchRequest<CDLogMessage>(entityName: Constants.model)
            fetchRequest.predicate = NSPredicate(value: true)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            fetchRequest.fetchLimit = 1
            let results = try context.fetch(fetchRequest)

            if let first = results.first {
                fetchedLogMessage = LogMessage(timestamp: first.timestamp, message: first.message)
            }
        }

        return fetchedLogMessage
    }

    public func getLastLog() throws -> LogMessage? {
        var fetchedLogMessage: LogMessage?
        try context.executePerformAndWait {
            let fetchRequest = NSFetchRequest<CDLogMessage>(entityName: Constants.model)
            fetchRequest.predicate = NSPredicate(value: true)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchLimit = 1
            let results = try context.fetch(fetchRequest)

            if let last = results.last {
                fetchedLogMessage = LogMessage(timestamp: last.timestamp, message: last.message)
            }
        }

        return fetchedLogMessage
    }

    public func fetchPeriod(_ from: Date, _ to: Date) throws -> [LogMessage] {
        var fetchedLogs: [LogMessage] = []

        try context.executePerformAndWait {
            let fetchRequest = NSFetchRequest<CDLogMessage>(entityName: Constants.model)
            fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                                 from as NSDate,
                                                 to as NSDate)
            let logs = try context.fetch(fetchRequest)
            fetchedLogs = logs.map { LogMessage(timestamp: $0.timestamp, message: $0.message) }
        }

        return fetchedLogs
    }

    public func delete() throws {
        try context.executePerformAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.model)
            let count = try context.count(for: request)
            let limit: Double = (Double(count) * 0.1).rounded() // 10% percent of all records should be removed
            request.fetchLimit = Int(limit)
            request.includesPropertyValues = false
            let results = try context.fetch(request)

            results.compactMap { $0 as? NSManagedObject }.forEach {
                context.delete($0)
            }

            try saveEvent(withContext: context)
            Logger.common(message: "10%  logs has been deleted", level: .debug, category: .general)
        }
    }

    public func deleteAll() throws {
        try context.executePerformAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.model)
            request.includesPropertyValues = false
            let results = try context.fetch(request)
            results.compactMap { $0 as? NSManagedObject }.forEach {
                context.delete($0)
            }
        }
    }
}

private extension MBLoggerCoreDataManager {
    private func saveEvent(withContext context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try saveContext(context)
    }

    private func saveContext(_ context: NSManagedObjectContext) throws {
        do {
            try context.save()
        } catch {
            switch error {
            case let error as NSError where error.domain == NSSQLiteErrorDomain && error.code == 13:
                fallthrough
            default:
                context.rollback()
            }
            throw error
        }
    }

    private func getDBFileSize() -> Int {
        guard let url = context.persistentStoreCoordinator?.persistentStores.first?.url else {
            return 0
        }
        let size = url.fileSize / 1024 // Bytes to Kilobytes
        return Int(size)
    }
}
