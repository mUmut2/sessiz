import Foundation
import SpamCore
import UIKit

/// Keeps the message rules on disk (App Group) so the Message Filter extension can read them.
/// The extension only reads this file; it cannot write.
final class RuleStore: ObservableObject {
    @Published private(set) var ruleSet: RuleSet
    /// Plain Turkish message shown when saving failed or there is no shared folder.
    @Published private(set) var problem: String?

    private let fileURL: URL
    private let sharedFolderProblem: String?

    init() {
        let directory: URL
        var startupProblem: String?
        if let groupID = AppGroupConfig.identifier(),
           let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            directory = container
        } else {
            // No shared folder (e.g. unsigned build): rules still work in the app, but the filter cannot see them.
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            directory = support
            startupProblem = "Paylaşılan klasör açılamadı. Kurallar mesaj filtresine iletilemez."
        }
        fileURL = directory.appendingPathComponent(SharedFiles.messageRulesJSON)
        sharedFolderProblem = startupProblem

        let stored = try? Data(contentsOf: fileURL)
        ruleSet = RuleSet.load(from: stored)
        problem = startupProblem
        if stored == nil { save() }   // first launch: write the default pack so the filter has a file
    }

    var classifier: MessageClassifier { MessageClassifier(rules: ruleSet.rules) }

    /// Returns a Turkish error message, or nil on success.
    func addRule(pattern: String, target: RuleTarget, mode: MatchMode, action: RuleAction) -> String? {
        var updated = ruleSet
        switch updated.addUserRule(pattern: pattern, target: target, mode: mode, action: action) {
        case .failure(let error):
            return error.userMessage
        case .success:
            commit(updated)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return nil
        }
    }

    func setEnabled(_ enabled: Bool, for rule: MessageRule) {
        var updated = ruleSet
        updated.setEnabled(enabled, forRuleID: rule.id)
        commit(updated)
    }

    func remove(_ rule: MessageRule) {
        var updated = ruleSet
        updated.removeUserRule(id: rule.id)
        commit(updated)
    }

    func resetToDefaults() {
        var updated = ruleSet
        updated.resetToDefaults()
        commit(updated)
    }

    private func commit(_ updated: RuleSet) {
        ruleSet = updated
        save()
    }

    private func save() {
        do {
            try ruleSet.jsonData().write(to: fileURL, options: .atomic)
            problem = sharedFolderProblem
        } catch {
            problem = "Kurallar kaydedilemedi. Lütfen tekrar deneyin."
        }
    }
}
