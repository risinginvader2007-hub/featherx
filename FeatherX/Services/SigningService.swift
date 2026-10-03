import Foundation

struct SigningResult {
    let outputURL: URL
}

enum SigningService {
    static func statusText() -> String {
        "Signing engine interface prepared. Native on-device signing will use a bundled Swift signing implementation."
    }
}
