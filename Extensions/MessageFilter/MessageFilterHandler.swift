import Foundation
import IdentityLookup
import SpamCore

/// Decides for each incoming SMS/MMS from an unknown sender. Offline: reads the rules the app saved in the
/// App Group (read-only here) and runs the same `MessageClassifier` as the app's "Test et" screen.
final class MessageFilterHandler: ILMessageFilterExtension {}

extension MessageFilterHandler: ILMessageFilterQueryHandling {
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        response.action = action(for: queryRequest)
        completion(response)
    }

    private func action(for request: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        let classifier = MessageClassifier(rules: loadRules().rules)
        let verdict = classifier.classify(sender: request.sender, body: request.messageBody ?? "")
        // Only a rule match blocks. Everything else is let through (when unsure, pass).
        return verdict.isSpam ? .junk : .allow
    }

    /// Falls back to the default pack when the app has not saved anything yet (or the file is unreadable).
    private func loadRules() -> RuleSet {
        guard let groupID = AppGroupConfig.identifier(),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
        else { return .defaultSet }
        let file = container.appendingPathComponent(SharedFiles.messageRulesJSON)
        return RuleSet.load(from: try? Data(contentsOf: file))
    }
}
