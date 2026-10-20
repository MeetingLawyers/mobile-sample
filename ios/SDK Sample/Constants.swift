import Foundation

/// Demo credentials, read from the repo-root `.env` through `Config.xcconfig` and `Info.plist`.
enum Constants {
    static let apiKey = infoValue("MLApiKey")
    static let userId = infoValue("MLUserId")
    /// `PROD` points to production; anything else to the MeetingLawyers demo environment.
    static let isProduction = infoValue("MLEnvironment") == "PROD"

    /// Returns the Info.plist value for `key`, or an empty string when `.env` doesn't define it.
    private static func infoValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
