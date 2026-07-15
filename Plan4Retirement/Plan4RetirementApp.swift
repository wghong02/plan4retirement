//
//  Plan4RetirementApp.swift
//  Plan4Retirement
//
//  Created by Gilbert Hong on 7/14/26.
//

import CoreData
import SwiftUI

@main
struct Plan4RetirementApp: App {
    @StateObject var settings = SettingsService.shared
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
