import Foundation

public enum RuleAction: String, Codable, Equatable {
    case allow
    case block
}

public enum RuleTarget: String, Codable, Equatable {
    case body      // message text
    case sender    // sender name / number
}

public enum MatchMode: String, Codable, Equatable {
    case contains   // pattern appears anywhere
    case wholeWord  // pattern words appear as whole words, in order
    case prefix     // text starts with pattern
    case exact      // text equals pattern
}

/// One user-editable rule. Matching is Turkish-aware (see `TurkishText.fold`).
public struct MessageRule: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var pattern: String
    public var target: RuleTarget
    public var mode: MatchMode
    public var action: RuleAction
    public var isEnabled: Bool

    public init(id: String = UUID().uuidString,
                name: String,
                pattern: String,
                target: RuleTarget = .body,
                mode: MatchMode = .contains,
                action: RuleAction = .block,
                isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.pattern = pattern
        self.target = target
        self.mode = mode
        self.action = action
        self.isEnabled = isEnabled
    }

    /// Rules shipped with the app have ids starting with "default.".
    public var isDefault: Bool { id.hasPrefix("default.") }
}

/// The JSON document stored in the App Group.
public struct RuleSet: Codable, Equatable {
    public static let currentVersion = 1

    public var version: Int
    public var rules: [MessageRule]

    public init(version: Int = RuleSet.currentVersion, rules: [MessageRule]) {
        self.version = version
        self.rules = rules
    }

    public static var defaultSet: RuleSet { RuleSet(rules: DefaultRules.pack) }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(from data: Data) throws -> RuleSet {
        try JSONDecoder().decode(RuleSet.self, from: data)
    }
}

/// Default Turkish keyword pack. Users can switch rules off or add their own.
/// Patterns are written with Turkish letters; matching folds both sides.
public enum DefaultRules {
    private static func block(_ key: String, _ category: String, _ pattern: String,
                              mode: MatchMode = .contains) -> MessageRule {
        MessageRule(id: "default.block.\(key)", name: category, pattern: pattern,
                    target: .body, mode: mode, action: .block)
    }

    public static let pack: [MessageRule] = [
        // Bahis
        block("bahis", "Bahis", "bahis"),
        block("casino", "Bahis", "casino"),
        block("kacak", "Bahis", "kaçak", mode: .wholeWord),
        block("bonus", "Bahis", "bonus"),
        block("freespin", "Bahis", "freespin"),
        // Çekiliş / ödül
        block("cekilis", "Çekiliş", "çekiliş"),
        block("kazandiniz", "Çekiliş", "kazandınız"),
        block("tikla", "Çekiliş", "tıkla"),
        // Borç / haciz tehdidi
        block("haciz", "Borç tehdidi", "haciz"),
        block("icra", "Borç tehdidi", "icra", mode: .wholeWord),
        block("borcunuz", "Borç tehdidi", "borcunuz"),
        block("yasal-takip", "Borç tehdidi", "yasal takip"),
        // Kısaltılmış link servisleri
        block("link-bitly", "Kısaltılmış link", "bit.ly/"),
        block("link-tinyurl", "Kısaltılmış link", "tinyurl.com"),
        block("link-cuttly", "Kısaltılmış link", "cutt.ly/"),
        block("link-tly", "Kısaltılmış link", "t.ly/"),
        block("link-isgd", "Kısaltılmış link", "is.gd/"),
        block("link-rbgy", "Kısaltılmış link", "rb.gy/"),
        block("link-shorturl", "Kısaltılmış link", "shorturl.at/"),
        block("link-owly", "Kısaltılmış link", "ow.ly/"),
        block("link-googl", "Kısaltılmış link", "goo.gl/"),
        block("link-tree", "Kısaltılmış link", "tr.ee/")
    ]
}
