//
//  SubTrackerApp.swift
//  SubTracker
//
//  Created by Karol on 02/05/2026.
//

import SwiftUI
import SwiftData

@main
struct SubTrackerApp: App {
    @State private var isSplashScreenActive = true
    
    var body: some Scene {
        WindowGroup {
            if isSplashScreenActive {
                SplashScreenView()
                    .onAppear {
                        // Skrócony czas z 3.0 do 1.8 sekundy
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            self.isSplashScreenActive = false
                        }
                    }
            } else {
                ContentView()
            }
        }
        .modelContainer(for: Subscription.self)
    }
}
