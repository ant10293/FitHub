//
//  Persistence.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/29/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    

   /* init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitHub")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
}*/

    init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "FitHub")

            // Support lightweight migrations & automatic inference
            if let description = container.persistentStoreDescriptions.first {
                description.shouldInferMappingModelAutomatically = true
                description.shouldMigrateStoreAutomatically = true

                if inMemory {
                    description.url = URL(fileURLWithPath: "/dev/null")
                } else {
                    // Use Documents directory for persistent store
                    let storeURL = FileManager.default
                        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                        .first?
                        .appendingPathComponent("FitHub.sqlite")
                    description.url = storeURL
                }
            }

            container.loadPersistentStores(completionHandler: { storeDescription, error in
                if let error = error as NSError? {
                    // Log error and attempt recovery if possible
                    #if DEBUG
                    fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
                    #else
                    print("Core Data load error: \(error.localizedDescription)")
                    #endif
                }
            })

            // Merge changes from parent contexts automatically
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            // Improve performance by turning off undo manager
            container.viewContext.undoManager = nil
        }

        /// Helper to save the view context safely
        func saveContext() {
            let context = container.viewContext
            guard context.hasChanges else { return }
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save Core Data context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
