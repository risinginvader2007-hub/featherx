import SwiftUI

struct AppsView: View {
    @EnvironmentObject private var state: AppState
    @State private var importing = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if state.apps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack.3d.up").font(.system(size: 48))
                        Text("Your Library").font(.title2.bold())
                        Text("Import an IPA to get started.").foregroundStyle(.secondary)
                        Button("Import IPA") { importing = true }.buttonStyle(.borderedProminent)
                    }
                } else {
                    List(state.apps) { app in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 14) {
                                Image(systemName: "app.fill").font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name).font(.headline)
                                    Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                                    Text("v\(app.version) (\(app.build))").font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            if let signed = app.signedFileName, let url = try? libraryURL(signed), FileManager.default.fileExists(atPath: url.path) {
                                HStack {
                                    Label("Signed IPA ready", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green)
                                    Spacer()
                                    ShareLink(item: url) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }.scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("FeatherX")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { importing = true } label: { Image(systemName: "plus") } } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.ipa], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls): if let u = urls.first { importIPA(u) }
                case .failure(let e): error = e.localizedDescription
                }
            }
            .alert("Import Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") {} } message: { Text(error ?? "") }
        }
    }

    private func libraryURL(_ fileName: String) throws -> URL {
        try FileImportService.libraryFolder().appendingPathComponent(fileName)
    }

    private func importIPA(_ url: URL) {
        do {
            let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
            let dest = try FileImportService.copyIntoLibrary(url)
            let m = try IPAService.metadata(from: dest)
            state.addApp(ManagedApp(name: m.name, bundleIdentifier: m.bundleID, version: m.version, build: m.build, fileName: dest.lastPathComponent))
        } catch { error = error.localizedDescription }
    }
}
