import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("FeatherX") { LabeledContent("Version", value: "0.1.0"); LabeledContent("Minimum iOS", value: "17.0") }
                Section("Security") { Text("Never commit a P12, PFX, private key, or certificate password to GitHub.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("Settings")
        }
    }
}
