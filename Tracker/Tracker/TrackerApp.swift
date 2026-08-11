//
//  TrackerApp.swift
//  Tracker
//
//  Created by Fin on 11.08.26.
//

import SwiftUI
import SwiftData

@main
struct TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ActivityGroup.self,
            ActivityButton.self,
            LogEntry.self,
            WellbeingEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
