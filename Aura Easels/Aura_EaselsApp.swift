//
// Aura Easels
// Aura_EaselsApp.swift
//
// Created on 7/1/25
//
// Copyright ©2025 DoorHinge Apps.
//


import SwiftUI
import SwiftData

@main
struct Aura_EaselsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Canvas.self,
            CanvasElement.self,
            TextStyleOptions.self
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
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
