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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ChronoFlowMainView()
                // Force dark mode for the high-contrast look
                .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
