//
//  toDoListApp.swift
//  toDoList
//
//  Created by Kenan TURAN on 17.12.2024.
//

import SwiftUI

@main
struct toDoListApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
