import Foundation

/// Locale-independent Turkish-aware text folding.
/// Done by hand (not `tr_TR` locale APIs) so results are identical on Linux CI and on iOS.
/// Folding: lowercase, I/İ/ı -> i, ş->s, ğ->g, ü->u, ö->o, ç->c, â->a, î->i, û->u,
/// combining marks dropped, no-break space -> space.
public enum TurkishText {
    public static func fold(_ input: String) -> String {
        var result = ""
        for scalar in input.unicodeScalars {
            switch scalar.value {
            case 0x0300...0x036F:
                continue                                   // combining marks (e.g. dot above of decomposed İ)
            case 0x49, 0x69, 0x0130, 0x0131, 0xCE, 0xEE:   // I i İ ı Î î
                result.append("i")
            case 0xC7, 0xE7:                               // Ç ç
                result.append("c")
            case 0x011E, 0x011F:                           // Ğ ğ
                result.append("g")
            case 0xD6, 0xF6:                               // Ö ö
                result.append("o")
            case 0x015E, 0x015F:                           // Ş ş
                result.append("s")
            case 0xDC, 0xFC, 0xDB, 0xFB:                   // Ü ü Û û
                result.append("u")
            case 0xC2, 0xE2:                               // Â â
                result.append("a")
            case 0xA0:
                result.append(" ")
            case 0x41...0x5A:                              // other ASCII upper-case
                result.unicodeScalars.append(Unicode.Scalar(scalar.value + 32)!)
            default:
                result.append(contentsOf: String(scalar).lowercased())
            }
        }
        return result
    }

    /// Splits already-folded text into letter/digit runs.
    public static func tokens(ofFolded folded: String) -> [String] {
        folded
            .split(whereSeparator: { !($0.isLetter || $0.isNumber) })
            .map(String.init)
    }

    /// Folded text with everything except letters and digits removed (for sender names like "E-Devlet").
    public static func key(of text: String) -> String {
        String(fold(text).filter { $0.isLetter || $0.isNumber })
    }

    /// True if `needle` appears as consecutive tokens in `tokens`.
    /// With `prefixLast`, the last needle token may be only a prefix of the haystack token.
    static func containsSequence(_ tokens: [String], _ needle: [String], prefixLast: Bool = false) -> Bool {
        guard !needle.isEmpty, tokens.count >= needle.count else { return false }
        for start in 0...(tokens.count - needle.count) {
            var matched = true
            for (offset, word) in needle.enumerated() {
                let candidate = tokens[start + offset]
                let isLast = offset == needle.count - 1
                if isLast && prefixLast {
                    if !candidate.hasPrefix(word) { matched = false; break }
                } else if candidate != word {
                    matched = false
                    break
                }
            }
            if matched { return true }
        }
        return false
    }
}
