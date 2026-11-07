import CallKit
import Foundation
import SpamCore

/// Loads the blocked numbers from the App Group text list, streaming line by line
/// (extensions have a very small memory limit). Numbers must be added in ascending order;
/// `CallDirectoryFile.forEachNumber` guarantees that.
final class CallDirectoryHandler: CXCallDirectoryProvider {
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        // Always rebuild from scratch; also correct when iOS asks for an incremental load.
        if context.isIncremental {
            context.removeAllBlockingEntries()
        }

        if let groupID = AppGroupConfig.identifier(),
           let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let file = container.appendingPathComponent(SharedFiles.callDirectoryList)
            if FileManager.default.fileExists(atPath: file.path) {
                do {
                    try CallDirectoryFile.forEachNumber(at: file) { number in
                        context.addBlockingEntry(withNextSequentialPhoneNumber: number)
                    }
                } catch {
                    context.cancelRequest(withError: error)
                    return
                }
            }
        }
        context.completeRequest()
    }
}
