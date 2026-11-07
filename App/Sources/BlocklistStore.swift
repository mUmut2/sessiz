import CallKit
import Foundation
import SpamCore
import UIKit

/// Keeps the blocked-number list on disk (App Group) and tells iOS to reload the Call Directory extension.
final class BlocklistStore: ObservableObject {
    @Published private(set) var blocklist = Blocklist()
    /// Plain Turkish message shown under the list when saving or reloading failed.
    @Published private(set) var problem: String?
    /// Which built-in spam list levels are on (stored on the device only).
    @Published private(set) var protection: ProtectionSettings

    private let directory: URL
    private static let protectionKey = "protectionSettings"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.protectionKey),
           let saved = try? JSONDecoder().decode(ProtectionSettings.self, from: data) {
            protection = saved
        } else {
            protection = ProtectionSettings()
        }
        if let groupID = AppGroupConfig.identifier(),
           let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            directory = container
        } else {
            // No shared folder (e.g. unsigned build): the list still works in the app, but the extension cannot see it.
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            directory = support
            problem = "Paylaşılan klasör açılamadı. Numaralar arama engellemeye iletilemez."
        }
        load()
        syncCallList()
    }

    private var jsonURL: URL { directory.appendingPathComponent(SharedFiles.blocklistJSON) }
    private var listURL: URL { directory.appendingPathComponent(SharedFiles.callDirectoryList) }

    private func load() {
        guard let data = try? Data(contentsOf: jsonURL),
              let decoded = try? Blocklist.decode(from: data) else { return }
        blocklist = decoded
    }

    /// Returns a Turkish error message, or nil on success.
    func add(input: String, label: String) -> String? {
        var updated = blocklist
        switch updated.add(input: input, label: label) {
        case .failure(let error):
            return error.userMessage
        case .success:
            commit(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return nil
        }
    }

    func setProtection(_ level: ProtectionLevel, on: Bool) {
        var updated = protection
        updated.set(level, to: on)
        protection = updated
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: Self.protectionKey)
        }
        commit(blocklist)
    }

    func remove(_ number: BlockedNumber) {
        var updated = blocklist
        updated.remove(number.e164)
        commit(updated)
    }

    private func commit(_ updated: Blocklist) {
        blocklist = updated
        do {
            try updated.jsonData().write(to: jsonURL, options: .atomic)
            try callListText(for: updated).write(to: listURL, atomically: true, encoding: .utf8)
            problem = nil
        } catch {
            problem = "Liste kaydedilemedi. Lütfen tekrar deneyin."
            return
        }
        reloadExtension()
    }

    private func callListText(for list: Blocklist) -> String {
        CallDirectoryBuilder.text(user: list.entries.map(\.e164), protection: protection)
    }

    /// At launch: if the app update changed the built-in list, rewrite the file and reload the extension.
    private func syncCallList() {
        let text = callListText(for: blocklist)
        let current = try? String(contentsOf: listURL, encoding: .utf8)
        guard current != text else { return }
        guard (try? text.write(to: listURL, atomically: true, encoding: .utf8)) != nil else { return }
        reloadExtension(reportErrors: false)   // quiet: the extension may simply not be switched on yet
    }

    private func reloadExtension(reportErrors: Bool = true) {
        guard let identifier = AppIdentity.callDirectoryExtensionID else { return }
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { [weak self] error in
            guard error != nil, reportErrors else { return }
            DispatchQueue.main.async {
                self?.problem = "Liste arama engellemeye iletilemedi. Durum sekmesinde arama engellemenin açık olduğundan emin olun."
            }
        }
    }
}
