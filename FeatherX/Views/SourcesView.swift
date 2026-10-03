import SwiftUI

struct SourcesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Library") {
                    Label("On This iPhone", systemImage: "iphone")
                    Text("Imported IPA files remain in FeatherX local storage.").font(.caption).foregroundStyle(.secondary)
                }
            }.navigationTitle("Sources")
        }
    }
}
