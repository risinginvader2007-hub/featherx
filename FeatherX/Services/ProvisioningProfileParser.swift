import Foundation

enum ProvisioningProfileParser {
    static func parse(_ data: Data) -> (name: String, appID: String, expiration: Date?) {
        let open = Data("<plist".utf8), close = Data("</plist>".utf8)
        guard let start = data.range(of: open), let end = data.range(of: close, options: [], in: start.lowerBound..<data.endIndex) else { return ("Provisioning Profile", "Unknown", nil) }
        let plistData = data[start.lowerBound..<end.upperBound]
        guard let object = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil), let dict = object as? [String: Any] else { return ("Provisioning Profile", "Unknown", nil) }
        let entitlements = dict["Entitlements"] as? [String: Any]
        return (dict["Name"] as? String ?? "Provisioning Profile", entitlements?["application-identifier"] as? String ?? "Unknown", dict["ExpirationDate"] as? Date)
    }
}
