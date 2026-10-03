import Foundation

enum IPAService {
    static func metadata(from url: URL) throws -> (name: String, bundleID: String, version: String, build: String) {
        (url.deletingPathExtension().lastPathComponent, "Unknown", "Unknown", "Unknown")
    }
}
