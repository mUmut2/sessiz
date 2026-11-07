import Foundation

enum AppIdentity {
    /// Bundle id of the Call Directory extension (app id + ".CallDirectory", see project.yml).
    static var callDirectoryExtensionID: String? {
        Bundle.main.bundleIdentifier.map { $0 + ".CallDirectory" }
    }
}
