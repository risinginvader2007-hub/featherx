import Foundation

struct ManagedApp: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var version: String
    var build: String
    var fileName: String
    var importedAt: Date

    init(name: String, bundleIdentifier: String = "Unknown", version: String = "Unknown", build: String = "Unknown", fileName: String) {
        id = UUID(); self.name = name; self.bundleIdentifier = bundleIdentifier; self.version = version; self.build = build; self.fileName = fileName; importedAt = Date()
    }
}
