import SwiftUI

struct SigningView: View {
    @EnvironmentObject private var state: AppState
    enum ImportKind { case certificate, profile }
    @State private var importKind: ImportKind?
    @State private var showingImporter = false
    @State private var selectedApp: ManagedApp?
    @State private var password = ""
    @State private var showingPassword = false
    @State private var status: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Certificates") {
                    if state.certificates.isEmpty {
                        Text("No certificates imported")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(state.certificates) { asset in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(asset.displayName)
                                    .font(.headline)
                                Text(asset.fileName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 7)
                        }
                    }

                    Button {
                        importKind = .certificate
                        showingImporter = true
                    } label: {
                        Label("Import P12 / PFX", systemImage: "key.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)
                }

                Section("Provisioning Profiles") {
                    if state.profiles.isEmpty {
                        Text("No provisioning profiles imported")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(state.profiles) { asset in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(asset.displayName)
                                    .font(.headline)
                                Text(asset.details)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 7)
                        }
                    }

                    Button {
                        importKind = .profile
                        showingImporter = true
                    } label: {
                        Label("Import Mobileprovision", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 44)
                }

                Section("Sign IPA") {
                    if state.apps.isEmpty {
                        Text("Import an IPA from the Apps tab first.")
                            .foregroundStyle(.secondary)
                    } else if state.certificates.isEmpty || state.profiles.isEmpty {
                        Text("Import a P12/PFX and provisioning profile to enable signing.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(state.apps) { app in
                            Button {
                                selectedApp = app
                                showingPassword = true
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(app.name)
                                            .font(.headline)
                                        Text(app.bundleIdentifier)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "signature")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .frame(minHeight: 52)
                        }
                    }
                }

                Section {
                    Text("Private signing material remains on-device. FeatherX uses the imported certificate and provisioning profile to create a signed IPA.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Signing")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                switch importKind {
                case .certificate: importCertificate(result)
                case .profile: importProfile(result)
                case nil: break
                }
            }
            .sheet(isPresented: $showingPassword) {
                NavigationStack {
                    Form {
                        Section("Certificate Password") {
                            SecureField("P12 / PFX password", text: $password)
                        }

                        Button("Sign IPA") {
                            signSelectedApp()
                        }
                        .disabled(password.isEmpty)
                    }
                    .navigationTitle("Sign App")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingPassword = false
                            }
                        }
                    }
                }
            }
            .alert(
                "FeatherX",
                isPresented: Binding(
                    get: { status != nil },
                    set: { if !$0 { status = nil } }
                )
            ) {
                Button("OK") {}
            } message: {
                Text(status ?? "")
            }
        }
    }

    private func libraryURL(_ fileName: String) throws -> URL {
        try FileImportService.libraryFolder().appendingPathComponent(fileName)
    }

    private func signSelectedApp() {
        guard let app = selectedApp,
              let certificate = state.certificates.first,
              let profile = state.profiles.first else { return }

        do {
            let input = try libraryURL(app.fileName)
            let p12 = try libraryURL(certificate.fileName)
            let prov = try libraryURL(profile.fileName)
            let output = try FileImportService.libraryFolder()
                .appendingPathComponent("\(app.name)-signed.ipa")

            let parsedProfile = ProvisioningProfileParser.parse(try Data(contentsOf: prov))
            let profileBundleID = parsedProfile.appID
                .split(separator: ".", maxSplits: 1)
                .dropFirst().first.map(String.init) ?? ""
            let bundleID = (profileBundleID.isEmpty || profileBundleID.contains("*"))
                ? app.bundleIdentifier : profileBundleID

            try SigningService.sign(
                ipaURL: input,
                p12URL: p12,
                profileURL: prov,
                password: password,
                bundleIdentifier: bundleID,
                outputURL: output
            )

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
                let access = url.startAccessingSecurityScopedResource()
                defer {
                    if access {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let ext = url.pathExtension.lowercased()
                guard ext == "p12" || ext == "pfx" else {
                    throw NSError(
                        domain: "FeatherX",
                        code: 1001,
                        userInfo: [NSLocalizedDescriptionKey: "Please select a .p12 or .pfx certificate file."]
                    )
                }

                let dest = try FileImportService.copyIntoLibrary(url)

                state.addCertificate(
                    SigningAsset(
                        fileName: dest.lastPathComponent,
                        displayName: dest.deletingPathExtension().lastPathComponent
                    )
                )

                status = "Certificate imported successfully."
            } catch {
                status = "Certificate import failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            status = "Certificate import failed: \(error.localizedDescription)"
        }
    }

    private func importProfile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                let access = url.startAccessingSecurityScopedResource()
                defer {
                    if access {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard url.pathExtension.lowercased() == "mobileprovision" else {
                    throw NSError(
                        domain: "FeatherX",
                        code: 1002,
                        userInfo: [NSLocalizedDescriptionKey: "Please select a .mobileprovision file."]
                    )
                }

                let data = try Data(contentsOf: url)
                let parsed = ProvisioningProfileParser.parse(data)
                let dest = try FileImportService.copyIntoLibrary(url)

                state.addProfile(
                    SigningAsset(
                        fileName: dest.lastPathComponent,
                        displayName: parsed.name,
                        details: parsed.appID
                    )
                )

                status = "Provisioning profile imported successfully."
            } catch {
                status = "Provisioning profile import failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            status = "Provisioning profile import failed: \(error.localizedDescription)"
        }
    }
}
