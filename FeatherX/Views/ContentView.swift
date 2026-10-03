import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            AppsView()
                .tabItem { Label("Apps", systemImage: "square.grid.2x2.fill") }
            SourcesView()
                .tabItem { Label("Sources", systemImage: "shippingbox.fill") }
            SigningView()
                .tabItem { Label("Signing", systemImage: "signature") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

extension UTType {
    static var ipa: UTType {
        UTType(filenameExtension: "ipa") ?? .data
    }

    static var p12: UTType {
        UTType(filenameExtension: "p12", conformingTo: .data) ?? .data
    }

    static var pfx: UTType {
        UTType(filenameExtension: "pfx", conformingTo: .data) ?? .data
    }

    static var mobileprovision: UTType {
        UTType(filenameExtension: "mobileprovision", conformingTo: .data) ?? .data
    }
}
