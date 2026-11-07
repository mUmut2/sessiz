import Foundation

public enum PhoneNormalizationError: Error, Equatable {
    case empty
    case invalidCharacters
    case tooShort
    case tooLong
    case invalidFormat
    case shortNumberUnsupported

    /// Plain Turkish message, safe to show to the user.
    public var userMessage: String {
        switch self {
        case .empty:
            return "Bir numara yazın."
        case .invalidCharacters:
            return "Numarada yalnızca rakam, boşluk, tire ve parantez olabilir. Başa + koyabilirsiniz."
        case .tooShort:
            return "Numara çok kısa. Örnek: 0555 123 45 67"
        case .tooLong:
            return "Numara çok uzun. Örnek: 0555 123 45 67"
        case .invalidFormat:
            return "Bu numara geçerli görünmüyor. Örnek: 0555 123 45 67 veya +90 850 123 45 67"
        case .shortNumberUnsupported:
            return "444'lü kısa numaralar eklenemez."
        }
    }
}

/// Turns user input into an E.164 integer (what CallKit needs), e.g. 905551234567.
public enum PhoneNormalizer {
    private static let separators: Set<Character> = [
        " ", "\t", "-", "(", ")", ".", "/", "\u{00A0}", "\u{2010}", "\u{2011}", "\u{2013}", "\u{2014}"
    ]

    public static func normalize(_ input: String) -> Result<Int64, PhoneNormalizationError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .failure(.empty) }

        var digits = ""
        var hasPlus = false
        for (offset, character) in trimmed.enumerated() {
            if character == "+" {
                if offset == 0 { hasPlus = true; continue }
                return .failure(.invalidCharacters)
            }
            if let ascii = character.asciiValue, ascii >= 48, ascii <= 57 {
                digits.append(character)
                continue
            }
            if separators.contains(character) { continue }
            return .failure(.invalidCharacters)
        }
        if digits.isEmpty { return .failure(.empty) }

        var rest = digits
        var international = hasPlus
        if !international, rest.hasPrefix("00") {
            international = true
            rest.removeFirst(2)
        }

        if international {
            if rest.isEmpty || rest.hasPrefix("0") { return .failure(.invalidFormat) }
            if rest.hasPrefix("90") { return validateTurkish(String(rest.dropFirst(2))) }
            if rest.count < 8 { return .failure(.tooShort) }
            if rest.count > 15 { return .failure(.tooLong) }
            guard let value = Int64(rest) else { return .failure(.invalidFormat) }
            return .success(value)
        }

        if rest.hasPrefix("0") { return validateTurkish(String(rest.dropFirst())) }
        if rest.hasPrefix("90"), rest.count == 12 { return validateTurkish(String(rest.dropFirst(2))) }
        return validateTurkish(rest)
    }

    /// `national` = the 10 digits after +90 (no leading 0).
    private static func validateTurkish(_ national: String) -> Result<Int64, PhoneNormalizationError> {
        if national.count == 7, national.hasPrefix("444") { return .failure(.shortNumberUnsupported) }
        if national.count < 10 { return .failure(.tooShort) }
        if national.count > 10 { return .failure(.tooLong) }
        guard let first = national.first, "234589".contains(first) else { return .failure(.invalidFormat) }
        guard let value = Int64("90" + national) else { return .failure(.invalidFormat) }
        return .success(value)
    }
}

public enum PhoneFormatter {
    /// 905551234567 -> "+90 555 123 45 67"; other countries -> "+<digits>".
    public static func display(_ e164: Int64) -> String {
        let digits = String(e164)
        guard digits.hasPrefix("90"), digits.count == 12 else { return "+" + digits }
        let n = Array(digits.dropFirst(2))
        return "+90 " + String(n[0..<3]) + " " + String(n[3..<6]) + " " + String(n[6..<8]) + " " + String(n[8..<10])
    }
}

public enum NumberList {
    /// Call Directory requires ascending order and no duplicates.
    public static func sortedUnique(_ numbers: [Int64]) -> [Int64] {
        Array(Set(numbers)).sorted()
    }
}
