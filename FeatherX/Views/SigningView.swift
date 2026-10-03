import SwiftUI

struct SigningView: View {
    @EnvironmentObject private var state: AppState
    @State private var importingCertificate = false
    @State private var importingProfile = false
    @State private var selectedApp: ManagedApp?
    @State private var password = ""
    @State private var showingPassword = false
    @State private var status: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Certificates") {
                    ForEach(state.certificates) { asset in
                        VStack(alignment: .leading) { Text(asset.displayName); Text(asset.fileName).font(.caption).foregroundStyle(.secondary) }
                    }
                    Button { importingCertificate = true } label: { Label("Import P12 / PFX", systemImage: "key.fill") }
                }
                Section("Provisioning Profiles") {
                    ForEach(state.profiles) { asset in
                        VStack(alignment: .leading) { Text(asset.displayName); Text(asset.details).font(.caption).foregroundStyle(.secondary) }
                    }
                    Button { importingProfile = true } label: { Label("Import Mobileprovision", systemImage: "doc.badge.plus") }
                }
                Section("Sign IPA") {
                    if state.apps.isEmpty {
                        Text("Import an IPA from the Apps tab first.").foregroundStyle(.secondary)
                    } else if state.certificates.isEmpty || state.profiles.isEmpty {
                        Text("Import a P12/PFX and provisioning profile to enable signing.").foregroundStyle(.secondary)
                    } else {
                        ForEach(state.apps) { app in
                            Button { selectedApp = app; showingPassword = true } label: {
                                HStack {
                                    VStack(alignment: .leading) { Text(app.name); Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary) }
                                    Spacer(); Image(systemName: "signature")
                                }
                            }
                        }
                    }
                }
                Section { Text("Private signing material remains on-device. FeatherX uses the imported certificate and provisioning profile to create a signed IPA.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Signing")
            .fileImporter(isPresented: $importingCertificate, allowedContentTypes: [.data], allowsMultipleSelection: false) { importCertificate($0) }
            .fileImporter(isPresented: $importingProfile, allowedContentTypes: [.data], allowsMultipleSelection: false) { importProfile($0) }
            .sheet(isPresented: $showingPassword) {
                NavigationStack {
                    Form {
                        Section("Certificate Password") { SecureField("P12 / PFX password", text: $password) }
                        Button("Sign IPA") { signSelectedApp() }
                            .disabled(password.isEmpty)
                    }
                    .navigationTitle("Sign App")
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingPassword = false } } }
                }
            }
            .alert("FeatherX", isPresented: Binding(get: { status != nil }, set: { if !$0 { status = nil } })) { Button("OK") {} } message: { Text(status ?? "") }
        }
    }

    private func libraryURL(_ fileName: String) throws -> URL {
        try FileImportService.libraryFolder().appendingPathComponent(fileName)
    }

    private func signSelectedApp() {
        guard let app = selectedApp, let certificate = state.certificates.first, let profile = state.profiles.first else { return }
        do {
            let input = try libraryURL(app.fileName)
            let p12 = try libraryURL(certificate.fileName)
            let prov = try libraryURL(profile.fileName)
            let output = try FileImportService.libraryFolder().appendingPathComponent("\(app.name)-signed.ipa")
            try SigningService.sign(ipaURL: input, p12URL: p12, profileURL: prov, password: password, outputURL: output)
            try KeychainService.savePassword(password, for: certificate.id.uuidString)
            state.markSigned(app.id, fileName: output.lastPathComponent)
            password = ""
            showingPassword = false
            status = "Signed IPA created. Open Apps to share it with FlareStore or another app."
        } catch {
            status = "Signing failed: \(error.localizedDescription)"
        }
    }

    private func importCertificate(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                let dest = try FileImportService.copyIntoLibrary(url)
                state.addCertificate(SigningAsset(fileName: dest.lastPathComponent, displayName: dest.deletingPathExtension().lastPathComponent))
            } catch { status = error.localizedDescription }
        case .failure(let error): status = error.localizedDescription
        }
    }

    private func importProfile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let parsed = ProvisioningProfileParser.parse(data)
                let dest = try FileImportService.copyIntoLibrary(url)
                state.addProfile(SigningAsset(fileName: dest.lastPathComponent, displayName: parsed.name, details: parsed.appID))
            } catch { status = error.localizedDescription }
        case .failure(let error): status = error.localizedDescription
        }
    }
}