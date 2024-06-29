//
//  FitHubApp.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/29/24.
//

import SwiftUI

@main
struct FitHubApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
