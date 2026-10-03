import Foundation
import RorkSign

enum SigningService {
    static func sign(ipaURL: URL, p12URL: URL, profileURL: URL, password: String, outputURL: URL) throws {
        let credential = try SigningIdentity(pkcs12Data: Data(contentsOf: p12URL), password: password)
        let profileData = try Data(contentsOf: profileURL)
        try RorkSigner.signIPA(at: ipaURL, outputURL: outputURL, identity: credential, options: AppSigningOptions(bundleIdentifier: "com.risinginvader.featherx", rootProvisioningProfile: profileData))
    }

    static func validate(p12URL: URL, profileURL: URL, password: String) throws -> String {
        let credentialData = try Data(contentsOf: p12URL)
        let profileData = try Data(contentsOf: profileURL)
        return try RorkSigner.validatedTeamIdentifier(provisioningProfileData: profileData, credentialData: credentialData, password: password)
    }
}