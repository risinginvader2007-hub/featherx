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
                    VStack(spacing: 18) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 56, weight: .medium))

                        Text("Your Library")
                            .font(.title.bold())

                        Text("Import an IPA to get started.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Button("Import IPA") {
                            importing = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                } else {
                    List(state.apps) { app in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 16) {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 30))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(app.name)
                                        .font(.headline)
                                    Text(app.bundleIdentifier)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("v(app.version) ((app.build))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            if let signed = app.signedFileName,
                               let url = try? libraryURL(signed),
                               FileManager.default.fileExists(atPath: url.path) {
                                HStack {
                                    Label("Signed IPA ready", systemImage: "checkmark.seal.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.green)

                                    Spacer()

                                    ShareLink(item: url) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("FeatherX")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        importing = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.ipa],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let u = urls.first {
                        importIPA(u)
                    }
                case .failure(let e):
                    error = e.localizedDescription
                }
            }
            .alert(
                "Import Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("OK") {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func libraryURL(_ fileName: String) throws -> URL {
        try FileImportService.libraryFolder().appendingPathComponent(fileName)
    }

    private func importIPA(_ url: URL) {
        do {
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let dest = try FileImportService.copyIntoLibrary(url)
            let m = try IPAService.metadata(from: dest)

            state.addApp(
                ManagedApp(
                    name: m.name,
                    bundleIdentifier: m.bundleID,
                    version: m.version,
                    build: m.build,
                    fileName: dest.lastPathComponent
                )
            )
        } catch let importError {
            error = importError.localizedDescription
        }
    }
}
