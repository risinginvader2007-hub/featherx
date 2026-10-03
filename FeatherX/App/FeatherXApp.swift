import SwiftUI

@main
struct FeatherXApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appState).preferredColorScheme(.dark)
        }
    }
}
