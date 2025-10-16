//
//  iTochkaApp.swift
//  iTochka
//
//  Created by Fedor Donskov on 15.10.2025.
//

import SwiftUI

@main
struct iTochkaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
