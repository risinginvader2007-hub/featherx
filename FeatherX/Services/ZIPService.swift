import Foundation

// Archive operations are isolated here so the signing engine can replace this
// implementation without changing the SwiftUI layer.
enum ZIPService {
    static func validateIPA(_ url: URL) throws {
        guard url.pathExtension.lowercased() == "ipa" else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}
