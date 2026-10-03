import SwiftUI

struct SigningView: View {
    @EnvironmentObject private var state: AppState
    @State private var importingCertificate = false
    @State private var importingProfile = false
    @State private var status: String?
    var body: some View {
        NavigationStack {
            List {
                Section("Certificates") {
                    ForEach(state.certificates) { asset in VStack(alignment: .leading) { Text(asset.displayName); Text(asset.fileName).font(.caption).foregroundStyle(.secondary) } }
                    Button { importingCertificate = true } label: { Label("Import P12 / PFX", systemImage: "key.fill") }
                }
                Section("Provisioning Profiles") {
                    ForEach(state.profiles) { asset in VStack(alignment: .leading) { Text(asset.displayName); Text(asset.details).font(.caption).foregroundStyle(.secondary) } }
                    Button { importingProfile = true } label: { Label("Import Mobileprovision", systemImage: "doc.badge.plus") }
                }
                Section("Signing") { Text("Signing material stays on-device. The native signing engine is the next build stage.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("Signing")
            .fileImporter(isPresented: $importingCertificate, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in importCertificate(result) }
            .fileImporter(isPresented: $importingProfile, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in importProfile(result) }
            .alert("FeatherX", isPresented: Binding(get: { status != nil }, set: { if !$0 { status = nil } })) { Button("OK") {} } message: { Text(status ?? "") }
        }
    }
    private func importCertificate(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): guard let url = urls.first else { return }; do { let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; let dest = try FileImportService.copyIntoLibrary(url); state.addCertificate(SigningAsset(fileName: dest.lastPathComponent, displayName: dest.deletingPathExtension().lastPathComponent)) } catch { status = error.localizedDescription }
        case .failure(let error): status = error.localizedDescription
        }
    }
    private func importProfile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls): guard let url = urls.first else { return }; do { let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); let p = ProvisioningProfileParser.parse(data); let dest = try FileImportService.copyIntoLibrary(url); state.addProfile(SigningAsset(fileName: dest.lastPathComponent, displayName: p.name, details: p.appID)) } catch { status = error.localizedDescription }
        case .failure(let error): status = error.localizedDescription
        }
    }
}
