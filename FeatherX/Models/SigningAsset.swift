import Foundation

struct SigningAsset: Identifiable, Codable, Hashable {
    let id: UUID
    var fileName: String
    var displayName: String
    var details: String
    var importedAt: Date
    init(fileName: String, displayName: String, details: String = "") {
        id = UUID(); self.fileName = fileName; self.displayName = displayName; self.details = details; importedAt = Date()
    }
}
