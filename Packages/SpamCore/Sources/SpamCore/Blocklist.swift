import Foundation

/// File names inside the App Group container.
public enum SharedFiles {
    /// Full data (numbers + notes), written and read by the app.
    public static let blocklistJSON = "blocklist.json"
    /// One E.164 number per line, ascending, no duplicates. Read line by line by the Call Directory extension
    /// (a plain text list can be streamed with almost no memory; a JSON array cannot).
    public static let callDirectoryList = "callblock.txt"
    /// Message rules (`RuleSet` JSON). Written by the app, read-only for the Message Filter extension.
    public static let messageRulesJSON = "messagerules.json"
}

public struct BlockedNumber: Codable, Equatable, Identifiable {
    public var e164: Int64
    public var label: String
    public var addedAt: Date

    public var id: Int64 { e164 }

    public init(e164: Int64, label: String = "", addedAt: Date = Date()) {
        self.e164 = e164
        self.label = label
        self.addedAt = addedAt
    }
}

public enum BlocklistError: Error, Equatable {
    case invalidNumber(PhoneNormalizationError)
    case duplicate

    /// Plain Turkish message, safe to show to the user.
    public var userMessage: String {
        switch self {
        case .invalidNumber(let reason): return reason.userMessage
        case .duplicate: return "Bu numara zaten listede."
        }
    }
}

/// The user's blocked-number list (pure logic; file access lives in the app).
public struct Blocklist: Codable, Equatable {
    public static let currentVersion = 1
    public static let maxLabelLength = 60

    public var version: Int
    /// Newest first.
    public private(set) var entries: [BlockedNumber]

    public init(entries: [BlockedNumber] = []) {
        self.version = Blocklist.currentVersion
        self.entries = entries
    }

    @discardableResult
    public mutating func add(input: String, label: String = "", now: Date = Date()) -> Result<BlockedNumber, BlocklistError> {
        switch PhoneNormalizer.normalize(input) {
        case .failure(let reason):
            return .failure(.invalidNumber(reason))
        case .success(let number):
            if entries.contains(where: { $0.e164 == number }) { return .failure(.duplicate) }
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            let entry = BlockedNumber(e164: number, label: String(trimmed.prefix(Blocklist.maxLabelLength)), addedAt: now)
            entries.insert(entry, at: 0)
            return .success(entry)
        }
    }

    public mutating func remove(_ e164: Int64) {
        entries.removeAll { $0.e164 == e164 }
    }

    /// Matches digits inside the number (leading zeros ignored) or text inside the note (Turkish-insensitive).
    public func filtered(by query: String) -> [BlockedNumber] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return entries }
        let digits = String(trimmed.filter { $0.isASCII && $0.isNumber }.drop(while: { $0 == "0" }))
        let text = TurkishText.fold(trimmed)
        return entries.filter { entry in
            if !digits.isEmpty, String(entry.e164).contains(digits) { return true }
            return TurkishText.fold(entry.label).contains(text)
        }
    }

    /// Content of `SharedFiles.callDirectoryList`.
    public var callDirectoryText: String {
        let numbers = NumberList.sortedUnique(entries.map(\.e164))
        return numbers.map(String.init).joined(separator: "\n") + (numbers.isEmpty ? "" : "\n")
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func decode(from data: Data) throws -> Blocklist {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Blocklist.self, from: data)
    }
}

/// Streaming readers used by the Call Directory extension (tiny memory limit).
public enum CallDirectoryFile {
    /// Reads a text file line by line in small chunks.
    public static func forEachLine(at url: URL, chunkSize: Int = 8192, _ body: (String) -> Void) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var pending = Data()
        while let chunk = try handle.read(upToCount: chunkSize), !chunk.isEmpty {
            pending.append(chunk)
            while let newline = pending.firstIndex(of: 0x0A) {
                if let line = String(data: pending[pending.startIndex..<newline], encoding: .utf8) { body(line) }
                pending.removeSubrange(pending.startIndex...newline)
            }
        }
        if !pending.isEmpty, let line = String(data: pending, encoding: .utf8) { body(line) }
    }

    /// Calls `body` for each valid number, strictly ascending. Lines that are not numbers, or are not greater
    /// than the previous one, are skipped (CallKit rejects the whole load if the order is broken).
    public static func forEachNumber(at url: URL, chunkSize: Int = 8192, _ body: (Int64) -> Void) throws {
        var previous: Int64 = 0
        try forEachLine(at: url, chunkSize: chunkSize) { line in
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let number = Int64(text), number > previous else { return }
            previous = number
            body(number)
        }
    }
}
