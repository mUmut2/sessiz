import Foundation

/// Built-in spam list levels. Each one can be switched on or off by the user.
public enum ProtectionLevel: String, CaseIterable, Codable {
    /// Individual numbers with several independent complaints.
    case basic
    /// Narrow 0850/0212 blocks where reports are concentrated (10.000 numbers each at most).
    case strict
    /// Numbers with a single complaint. Off by default.
    case suspicious
}

public struct ProtectionSettings: Equatable, Codable {
    public var basic: Bool
    public var strict: Bool
    public var suspicious: Bool

    public init(basic: Bool = true, strict: Bool = false, suspicious: Bool = false) {
        self.basic = basic
        self.strict = strict
        self.suspicious = suspicious
    }

    public func isOn(_ level: ProtectionLevel) -> Bool {
        switch level {
        case .basic: return basic
        case .strict: return strict
        case .suspicious: return suspicious
        }
    }

    public mutating func set(_ level: ProtectionLevel, to value: Bool) {
        switch level {
        case .basic: basic = value
        case .strict: strict = value
        case .suspicious: suspicious = value
        }
    }
}

/// A block of consecutive numbers (Call Directory has no wildcards; ranges are expanded one by one).
public struct NumberRange: Equatable {
    public let label: String   // e.g. "0850 484 xxxx"
    public let start: Int64
    public let count: Int64

    public var end: Int64 { start + count - 1 }

    public func contains(_ number: Int64) -> Bool { number >= start && number <= end }
}

/// Official numbers of banks, cargo companies and carriers. They are NEVER blocked by the built-in lists
/// (the user can still add one by hand). This is not a "trusted" label: scammers imitate these numbers.
public struct AllowedNumber: Equatable {
    public let owner: String
    public let display: String

    /// Parsed with the same normalizer the app uses for user input; nil only if the text above is wrong
    /// (a unit test guards this).
    public var e164: Int64? {
        if case .success(let value) = PhoneNormalizer.normalize(display) { return value }
        return nil
    }
}

public enum BuiltInSpamList {
    /// Date the list was last checked by hand. Shown in the app. Review every 6-12 months: 0850 numbers change hands.
    public static let reviewedOn = "2026-11-07"

    /// Several independent, dated complaints (sikayetvar.com, 2026).
    public static let basicNumbers: [Int64] = [
        908509010670,   // 0850 901 06 70  gambling voice-recording calls + SMS
        908509660674,   // 0850 966 06 74  gambling SMS (Turk Telekom and Vodafone subscribers)
        908504340555    // 0850 434 05 55  gambling SMS and calls
    ]

    /// Single-complaint numbers. Off by default, kept apart from the reliable list.
    public static let suspiciousNumbers: [Int64] = [
        908505529400, 908506330000, 908506330099, 908506781451, 908506781503,
        908506781078, 908504250497, 908504250854, 908507060792, 908509449337,
        903128390024, 902162030711, 908509010472, 908504809017, 903125370119
    ]

    /// Narrow blocks only. Never widen these to 0850 222 / 220 / 250 / 258 / 724 (banks live there);
    /// `BuiltInSpamListTests` fails if a range touches an allowed number.
    public static let strictRanges: [NumberRange] = [
        NumberRange(label: "0850 484 xxxx", start: 908504840000, count: 10_000),
        NumberRange(label: "0850 430 xxxx", start: 908504300000, count: 10_000),
        NumberRange(label: "0850 901 0xxx", start: 908509010000, count: 1_000),
        NumberRange(label: "0212 922 xxxx", start: 902129220000, count: 10_000)
    ]

    public static let allowlist: [AllowedNumber] = [
        AllowedNumber(owner: "Ziraat Bankası", display: "0850 220 00 00"),
        AllowedNumber(owner: "Ziraat Bankası", display: "0850 258 00 00"),
        AllowedNumber(owner: "İş Bankası", display: "0850 724 0 724"),
        AllowedNumber(owner: "Garanti BBVA", display: "0850 222 0 333"),
        AllowedNumber(owner: "Garanti BBVA", display: "0212 318 18 18"),
        AllowedNumber(owner: "Akbank", display: "0850 222 25 25"),
        AllowedNumber(owner: "Yapı Kredi", display: "0850 222 0 444"),
        AllowedNumber(owner: "VakıfBank", display: "0850 222 0 724"),
        AllowedNumber(owner: "Halkbank", display: "0850 222 0 400"),
        AllowedNumber(owner: "Halkbank", display: "0850 250 0 400"),
        AllowedNumber(owner: "Halkbank", display: "0850 222 0 401"),
        AllowedNumber(owner: "QNB", display: "0850 222 0 900"),
        AllowedNumber(owner: "QNB", display: "0850 222 1 900"),
        AllowedNumber(owner: "QNB", display: "0850 222 2 900"),
        AllowedNumber(owner: "DenizBank", display: "0850 222 0 800"),
        AllowedNumber(owner: "DenizBank", display: "0850 222 0 804"),
        AllowedNumber(owner: "DenizBank", display: "0850 222 0 802"),
        AllowedNumber(owner: "DenizBank", display: "0850 222 68 00"),
        AllowedNumber(owner: "MNG Kargo", display: "0850 222 06 06"),
        AllowedNumber(owner: "MNG Kargo", display: "0212 366 55 55"),
        AllowedNumber(owner: "Aras Kargo", display: "0216 538 55 00"),
        AllowedNumber(owner: "Turkcell", display: "0532 532 00 00"),
        AllowedNumber(owner: "Vodafone", display: "0542 542 00 00"),
        AllowedNumber(owner: "SGK", display: "0312 207 80 00"),
        AllowedNumber(owner: "Bankalar Birliği", display: "0850 222 28 22")
    ]

    public static var allowedNumbers: Set<Int64> {
        Set(allowlist.compactMap(\.e164))
    }

    /// How many numbers a level adds (before removing allowed ones).
    public static func count(for level: ProtectionLevel) -> Int {
        switch level {
        case .basic: return basicNumbers.count
        case .suspicious: return suspiciousNumbers.count
        case .strict: return strictRanges.reduce(0) { $0 + Int($1.count) }
        }
    }
}

/// Builds the final Call Directory list: user numbers + enabled built-in levels,
/// minus allowed institution numbers (from built-in levels only), ascending and unique.
public enum CallDirectoryBuilder {
    public static func numbers(user: [Int64], protection: ProtectionSettings) -> [Int64] {
        var builtIn: [Int64] = []
        if protection.basic { builtIn += BuiltInSpamList.basicNumbers }
        if protection.suspicious { builtIn += BuiltInSpamList.suspiciousNumbers }
        if protection.strict {
            for range in BuiltInSpamList.strictRanges {
                builtIn.append(contentsOf: stride(from: range.start, through: range.end, by: 1))
            }
        }
        let allowed = BuiltInSpamList.allowedNumbers
        let filtered = builtIn.filter { !allowed.contains($0) }
        // A number the user typed in by hand always stays, even if it is on the allowed list.
        return NumberList.sortedUnique(user + filtered)
    }

    public static func text(user: [Int64], protection: ProtectionSettings) -> String {
        let list = numbers(user: user, protection: protection)
        return list.map(String.init).joined(separator: "\n") + (list.isEmpty ? "" : "\n")
    }
}
