import Foundation

/// Reads the App Group id from the Info.plist key `SessizAppGroupID`
/// (filled from `APP_GROUP_ID` in project.yml), so the id lives in one place.
public enum AppGroupConfig {
    public static let infoPlistKey = "SessizAppGroupID"

    public static func identifier(in bundle: Bundle = .main) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String,
              !value.isEmpty else { return nil }
        return value
    }
}
