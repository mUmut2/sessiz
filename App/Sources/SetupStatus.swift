import CallKit
import Foundation

/// Reads whether the Call Directory extension is switched on in iOS Settings.
/// (The message filter cannot be read from code; the user confirms it by hand.)
final class SetupStatus: ObservableObject {
    enum Calls {
        case checking
        case enabled
        case disabled
        case unreadable   // unknown status or an error (e.g. simulator)
    }

    @Published private(set) var calls: Calls = .checking

    func refresh() {
        guard let identifier = AppIdentity.callDirectoryExtensionID else {
            calls = .unreadable
            return
        }
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: identifier) { [weak self] status, error in
            let result: Calls
            if error != nil {
                result = .unreadable
            } else {
                switch status {
                case .enabled: result = .enabled
                case .disabled: result = .disabled
                default: result = .unreadable
                }
            }
            DispatchQueue.main.async {
                self?.calls = result
            }
        }
    }

    /// Opens the Phone > Call Blocking & Identification page.
    func openCallSettings() {
        CXCallDirectoryManager.sharedInstance.openSettings { _ in }
    }
}
