import Foundation

public struct Verdict: Equatable {
    public enum Source: Equatable {
        case oneTimeCode
        case trustedSender(String)
        case rule(MessageRule)
        case noMatch
    }

    public let action: RuleAction
    public let source: Source

    public var isSpam: Bool { action == .block }

    /// Plain Turkish explanation for the "Test et" screen.
    public var explanation: String {
        switch source {
        case .oneTimeCode:
            return "Doğrulama kodu gibi görünüyor. Bu tür mesajlar her zaman geçer."
        case .trustedSender(let name):
            return "\(name) güvenli göndericiler arasında. Bu göndericiden gelen mesajlar her zaman geçer."
        case .rule(let rule):
            switch rule.action {
            case .allow: return "İzin kuralı eşleşti: \(rule.name) (\"\(rule.pattern)\")."
            case .block: return "Engelleme kuralı eşleşti: \(rule.name) (\"\(rule.pattern)\")."
            }
        case .noMatch:
            return "Hiçbir kural eşleşmedi. Mesaj geçer."
        }
    }
}

/// Order of decisions: built-in safe rules > user allow rules > block rules > pass.
/// When unsure the message passes.
public struct MessageClassifier {
    private struct Compiled {
        let rule: MessageRule
        let folded: String
        let tokens: [String]
    }

    private let allowRules: [Compiled]
    private let blockRules: [Compiled]

    /// Disabled rules and rules with an empty pattern are ignored.
    public init(rules: [MessageRule]) {
        var allow: [Compiled] = []
        var block: [Compiled] = []
        for rule in rules where rule.isEnabled {
            let folded = TurkishText.fold(rule.pattern).trimmingCharacters(in: .whitespacesAndNewlines)
            if folded.isEmpty { continue }
            let compiled = Compiled(rule: rule, folded: folded, tokens: TurkishText.tokens(ofFolded: folded))
            switch rule.action {
            case .allow: allow.append(compiled)
            case .block: block.append(compiled)
            }
        }
        allowRules = allow
        blockRules = block
    }

    public func classify(sender: String?, body: String) -> Verdict {
        let foldedBody = TurkishText.fold(body)
        let bodyTokens = TurkishText.tokens(ofFolded: foldedBody)
        let foldedSender = TurkishText.fold(sender ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let senderTokens = TurkishText.tokens(ofFolded: foldedSender)

        if SafeRules.isOneTimeCode(foldedBody: foldedBody, tokens: bodyTokens) {
            return Verdict(action: .allow, source: .oneTimeCode)
        }
        if let name = SafeRules.trustedSender(sender) {
            return Verdict(action: .allow, source: .trustedSender(name))
        }
        for compiled in allowRules
        where matches(compiled, body: foldedBody, bodyTokens: bodyTokens, sender: foldedSender, senderTokens: senderTokens) {
            return Verdict(action: .allow, source: .rule(compiled.rule))
        }
        for compiled in blockRules
        where matches(compiled, body: foldedBody, bodyTokens: bodyTokens, sender: foldedSender, senderTokens: senderTokens) {
            return Verdict(action: .block, source: .rule(compiled.rule))
        }
        return Verdict(action: .allow, source: .noMatch)
    }

    private func matches(_ compiled: Compiled,
                         body: String, bodyTokens: [String],
                         sender: String, senderTokens: [String]) -> Bool {
        let text = compiled.rule.target == .body ? body : sender
        let tokens = compiled.rule.target == .body ? bodyTokens : senderTokens
        switch compiled.rule.mode {
        case .contains:
            return text.contains(compiled.folded)
        case .wholeWord:
            return TurkishText.containsSequence(tokens, compiled.tokens)
        case .prefix:
            return text.hasPrefix(compiled.folded)
        case .exact:
            return text == compiled.folded
        }
    }
}
