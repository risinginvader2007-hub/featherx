import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var apps: [ManagedApp] = []
    @Published var certificates: [SigningAsset] = []
    @Published var profiles: [SigningAsset] = []
    private let stateURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("FeatherX", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        stateURL = folder.appendingPathComponent("state.json")
        load()
    }
    func addApp(_ app: ManagedApp) { apps.insert(app, at: 0); save() }
    func addCertificate(_ asset: SigningAsset) { certificates.insert(asset, at: 0); save() }
    func addProfile(_ asset: SigningAsset) { profiles.insert(asset, at: 0); save() }
    private func save() {
        let state = PersistedState(apps: apps, certificates: certificates, profiles: profiles)
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: stateURL, options: .atomic) }
    }
    private func load() {
        guard let data = try? Data(contentsOf: stateURL), let saved = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        apps = saved.apps; certificates = saved.certificates; profiles = saved.profiles
    }
    struct PersistedState: Codable { let apps: [ManagedApp]; let certificates: [SigningAsset]; let profiles: [SigningAsset] }
}
