import SwiftUI

@main
struct FastingTrackerApp: App {
    @StateObject private var fastingManager = FastingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fastingManager)
        }
    }
}
