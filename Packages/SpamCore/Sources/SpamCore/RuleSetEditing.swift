import Foundation

public enum RuleValidationError: Error, Equatable {
    case tooShort
    case duplicate
    case tooLong
    case tooMany

    /// Plain Turkish message, safe to show to the user.
    public var userMessage: String {
        switch self {
        case .tooShort: return "Kural çok kısa. En az 2 harf yazın."
        case .duplicate: return "Bu kural zaten var."
        case .tooLong: return "Kural çok uzun. En fazla \(RuleSet.maxPatternLength) harf olabilir."
        case .tooMany: return "En fazla \(RuleSet.maxUserRules) kendi kuralınız olabilir. Önce birkaçını silin."
        }
    }
}

extension RuleSet {
    /// Limits keep the rules file small: the message filter extension has little memory and little time.
    public static let maxPatternLength = 80
    public static let maxUserRules = 200
    static let maxFileBytes = 1_000_000

    /// Loads the stored rules. Missing or unreadable data falls back to the default pack,
    /// so the message filter still works before the app has ever saved anything.
    public static func load(from data: Data?) -> RuleSet {
        guard let data, data.count <= maxFileBytes, let decoded = try? RuleSet.decode(from: data) else { return .defaultSet }
        return decoded
    }

    public var userRules: [MessageRule] { rules.filter { !$0.isDefault } }
    public var defaultRules: [MessageRule] { rules.filter { $0.isDefault } }

    /// Adds a user rule. The name falls back to the pattern when empty.
    public mutating func addUserRule(name: String = "",
                                     pattern: String,
                                     target: RuleTarget,
                                     mode: MatchMode,
                                     action: RuleAction) -> Result<MessageRule, RuleValidationError> {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = TurkishText.fold(trimmed).trimmingCharacters(in: .whitespacesAndNewlines)
        if folded.count < 2 { return .failure(.tooShort) }
        if trimmed.count > Self.maxPatternLength { return .failure(.tooLong) }
        if userRules.count >= Self.maxUserRules { return .failure(.tooMany) }

        let exists = rules.contains {
            $0.target == target && $0.action == action && $0.mode == mode
                && TurkishText.fold($0.pattern).trimmingCharacters(in: .whitespacesAndNewlines) == folded
        }
        if exists { return .failure(.duplicate) }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let rule = MessageRule(name: cleanName.isEmpty ? trimmed : cleanName,
                               pattern: trimmed, target: target, mode: mode, action: action)
        rules.append(rule)
        return .success(rule)
    }

    public mutating func setEnabled(_ enabled: Bool, forRuleID id: String) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].isEnabled = enabled
    }

    /// Only user rules can be deleted; shipped rules can only be switched off.
    public mutating func removeUserRule(id: String) {
        rules.removeAll { $0.id == id && !$0.isDefault }
    }

    public mutating func resetToDefaults() {
        self = .defaultSet
    }
}
