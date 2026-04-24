import SwiftUI

@main
struct ImpressionTrackingPOCApp: App {
    @StateObject private var impressionStore = ImpressionStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(impressionStore)
            .preferredColorScheme(.dark)
        }
    }
}
