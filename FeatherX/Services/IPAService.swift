import Foundation
import RorkSign

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
        let report = try RorkSigner.extractIPAMetadata(at: url)
        guard !report.appBundleIdentifier.isEmpty else { throw IPAError.invalidInfoPlist }
        return (report.appName.isEmpty ? url.deletingPathExtension().lastPathComponent : report.appName,
                report.appBundleIdentifier,
                report.appVersion.isEmpty ? "Unknown" : report.appVersion,
                report.appVersion.isEmpty ? "Unknown" : report.appVersion)
    }
}