import Foundation
import ZipArchive

enum IPAService {
    enum IPAError: LocalizedError {
        case noAppBundle
        case invalidInfoPlist

        var errorDescription: String? {
            switch self {
            case .noAppBundle: return "The IPA does not contain a valid Payload/*.app bundle."
            case .invalidInfoPlist: return "The app bundle does not contain a readable Info.plist."
            }
        }
    }

    static func metadata(from url: URL) throws -> (name: String, bundleID: String, version: String, build: String) {
        try ZipArchiveReader.withFile(url.path) { reader in
            let directory = try reader.readDirectory()
            guard let infoEntry = directory.first(where: {
                let path = $0.filename
                return path.hasPrefix("Payload/") && path.hasSuffix(".app/Info.plist")
            }) else {
                throw IPAError.noAppBundle
            }

            let data = try reader.readFile(infoEntry)
            guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                  let info = plist as? [String: Any] else {
                throw IPAError.invalidInfoPlist
            }

            let bundleID = info["CFBundleIdentifier"] as? String ?? "Unknown"
            let name = (info["CFBundleDisplayName"] as? String)
                ?? (info["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            let version = info["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = info["CFBundleVersion"] as? String ?? "Unknown"

            return (name, bundleID, version, build)
        }
    }
}
