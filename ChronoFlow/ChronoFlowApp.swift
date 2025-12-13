//
//  ChronoFlowApp.swift
//  ChronoFlow
//
//  Created by Akinalp Fidan on 13.12.2025.
//

import SwiftUI

// Ensure your App entry point points here
@main
struct ChronoFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ChronoFlowMainView()
                // Force dark mode for the high-contrast look
                .preferredColorScheme(.dark)
        }
    }
}
