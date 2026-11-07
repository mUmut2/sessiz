import Foundation

/// Built-in "always pass" rules. These cannot be switched off: wrongly blocking a bank
/// or e-Devlet code is a serious bug, wrongly passing a spam is not.
enum SafeRules {

    // MARK: One-time codes

    private static let strongPrefixPhrases: [[String]] = [
        ["dogrulama"], ["onay", "kod"], ["guvenlik", "kod"], ["giris", "kod"], ["islem", "kod"],
        ["tek", "kullanimlik"], ["sifre"], ["parola"], ["verification"], ["3d", "secure"]
    ]
    private static let strongExactPhrases: [[String]] = [["otp"], ["pin"]]
    /// Weaker signals ("kodunuz: 1234"); only trusted when the message has no link.
    private static let genericPrefixPhrases: [[String]] = [["kod"]]
    private static let genericExactPhrases: [[String]] = [["code"]]

    static func isOneTimeCode(foldedBody: String, tokens: [String]) -> Bool {
        guard hasCodeDigits(foldedBody) else { return false }
        for phrase in strongPrefixPhrases where TurkishText.containsSequence(tokens, phrase, prefixLast: true) {
            return true
        }
        for phrase in strongExactPhrases where TurkishText.containsSequence(tokens, phrase) {
            return true
        }
        if !containsLink(foldedBody) {
            for phrase in genericPrefixPhrases where TurkishText.containsSequence(tokens, phrase, prefixLast: true) {
                return true
            }
            for phrase in genericExactPhrases where TurkishText.containsSequence(tokens, phrase) {
                return true
            }
        }
        return false
    }

    /// A run of 4-8 digits, or two 3-digit groups joined by one space or dash ("123 456").
    static func hasCodeDigits(_ folded: String) -> Bool {
        let chars = Array(folded)
        var runs: [(start: Int, end: Int)] = []   // end is exclusive
        var index = 0
        while index < chars.count {
            if isDigit(chars[index]) {
                let start = index
                while index < chars.count, isDigit(chars[index]) { index += 1 }
                runs.append((start, index))
            } else {
                index += 1
            }
        }
        for run in runs where (4...8).contains(run.end - run.start) { return true }
        if runs.count >= 2 {
            for i in 0..<(runs.count - 1) {
                let a = runs[i], b = runs[i + 1]
                if a.end - a.start == 3, b.end - b.start == 3, b.start - a.end == 1,
                   chars[a.end] == " " || chars[a.end] == "-" {
                    return true
                }
            }
        }
        return false
    }

    private static func isDigit(_ c: Character) -> Bool {
        guard let ascii = c.asciiValue else { return false }
        return ascii >= 48 && ascii <= 57
    }

    private static let linkMarkers = [
        "http", "www.", ".com", ".net", ".org", ".xyz", ".top", ".info", ".click", ".ly/", ".gl/", ".cc/", ".gd/"
    ]

    static func containsLink(_ folded: String) -> Bool {
        linkMarkers.contains { folded.contains($0) }
    }

    // MARK: Trusted senders (banks, e-Devlet, public institutions, carriers)

    static let trustedSenderNames: [String] = [
        // Banks and payment
        "AKBANK", "GARANTI", "GARANTI BBVA", "BBVA", "ISBANK", "IS BANKASI", "YAPI KREDI", "YAPIKREDI",
        "ZIRAAT", "ZIRAATBANK", "HALKBANK", "VAKIFBANK", "DENIZBANK", "QNB", "QNB FINANSBANK", "FINANSBANK",
        "TEB", "ING", "ING BANK", "ENPARA", "FIBABANKA", "ODEABANK", "KUVEYTTURK", "ALBARAKA", "ANADOLUBANK",
        "SEKERBANK", "HSBC", "ALTERNATIFBANK", "BURGANBANK", "TURKIYE FINANS", "VAKIF KATILIM",
        "ZIRAAT KATILIM", "EMLAK KATILIM", "PAPARA", "ININAL", "TOSLA", "PARAM", "PTT",
        // Public institutions
        "E-DEVLET", "EDEVLET", "TURKIYE.GOV", "SGK", "GIB", "MHRS", "E-NABIZ", "UYAP", "AFAD",
        // Mobile carriers
        "TURKCELL", "VODAFONE", "TURK TELEKOM", "TURKTELEKOM"
    ]

    private static let trustedSenderKeys: [String: String] = {
        var map: [String: String] = [:]
        for name in trustedSenderNames { map[TurkishText.key(of: name)] = name }
        return map
    }()

    /// Returns the trusted name if the sender equals one (spaces, dashes and case ignored).
    static func trustedSender(_ sender: String?) -> String? {
        guard let sender = sender else { return nil }
        let key = TurkishText.key(of: sender)
        return key.isEmpty ? nil : trustedSenderKeys[key]
    }
}
