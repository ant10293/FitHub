//
//  Persistence.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/29/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // MARK: – Public handles
    let container: NSPersistentContainer
    /// Main-queue context – use in SwiftUI views
    var viewContext: NSManagedObjectContext { container.viewContext }
    /// Private context for long-running imports / saves
    let bgContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitHub")

        if let desc = container.persistentStoreDescriptions.first {
            desc.shouldInferMappingModelAutomatically = true
            desc.shouldMigrateStoreAutomatically = true

            if inMemory {
                desc.url = URL(fileURLWithPath: "/dev/null")
            } else {
                if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    // ensure the directory exists
                    try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
                    desc.url = appSupport.appendingPathComponent("FitHub.sqlite")
                } else {
                    // optional fallback: Documents
                    if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        desc.url = docs.appendingPathComponent("FitHub.sqlite")
                    } else {
                        // Last resort fallback
                        desc.url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("FitHub.sqlite")
                    }
                }
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                #if DEBUG
                print("❌ CoreData load error: \(error), \(error.userInfo)")
                #else
                print("⚠️ CoreData load error:", error.localizedDescription)
                #endif
                // In production, we could show a user-friendly error message
                // or attempt to recover from the error
            }
        }

        // ‼️ put this here so it inherits the storeCoordinator
        bgContext = container.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        bgContext.name        = "FitHub.bg"

        // Main context settings
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy                         = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.undoManager                         = nil
    }

    // MARK: – Convenience helpers
    /// main-thread saves (e.g. small setting toggles)
    func saveViewContext() {
        guard viewContext.hasChanges else { return }
        viewContext.perform {
            do { try self.viewContext.save() }
            catch { print("⚠️ ViewContext save:", error.localizedDescription) }
        }
    }

    /// heavy inserts / updates – automatically merges into the main context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        bgContext.perform {
            block(self.bgContext)
            if self.bgContext.hasChanges {
                do { try self.bgContext.save() }
                catch { print("⚠️ BGContext save:", error.localizedDescription) }
            }
        }
    }
}
