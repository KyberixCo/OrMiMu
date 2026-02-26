//
//  OrMiMuApp.swift
//  OrMiMu
//
//  Created by Manuel Galindo on 7/02/24.
//

import SwiftUI
import SwiftData
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Customize window appearance
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.backgroundColor = NSColor(Color.kyberixBlack)
                window.isOpaque = true
                window.title = "OrMiMu"

                // Hide standard window buttons to replace or integrate custom logic if needed,
                // or just rely on SwiftUI toolbar background fixes.
                // For now, let's keep standard buttons but ensure the backing view is correct.
            }
        }
    }
}

@main
struct OrMiMuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MusicPath.self,
            SongItem.self,
            PlaylistItem.self
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
            ContentView()
                .background(Color.kyberixBlack)
                .ignoresSafeArea() // Ensure content goes behind title bar
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
        }
    }
}
