import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            AppsView().tabItem { Label("Apps", systemImage: "square.grid.2x2.fill") }
            SourcesView().tabItem { Label("Sources", systemImage: "shippingbox.fill") }
            SigningView().tabItem { Label("Signing", systemImage: "signature") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }.tint(.white)
    }
}

extension UTType { static var ipa: UTType { UTType(filenameExtension: "ipa") ?? .data } }
