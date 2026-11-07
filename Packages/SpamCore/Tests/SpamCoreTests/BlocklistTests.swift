import XCTest
@testable import SpamCore

final class BlocklistTests: XCTestCase {
    private func tempFile(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sessiz-\(UUID().uuidString).txt")
        try content.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testAddNormalizesAndPutsNewestFirst() {
        var list = Blocklist()
        XCTAssertEqual(try? list.add(input: "0555 123 45 67", label: " Bahisçi ").get().e164, 905551234567)
        _ = list.add(input: "0212 111 22 33")
        XCTAssertEqual(list.entries.map(\.e164), [902121112233, 905551234567])
        XCTAssertEqual(list.entries[1].label, "Bahisçi")
    }

    func testDuplicateInDifferentFormatIsRejected() {
        var list = Blocklist()
        _ = list.add(input: "0555 123 45 67")
        let result = list.add(input: "+90 (555) 123-45-67")
        XCTAssertEqual(result, .failure(.duplicate))
        XCTAssertEqual(list.entries.count, 1)
        XCTAssertFalse(BlocklistError.duplicate.userMessage.isEmpty)
    }

    func testInvalidNumberGivesTurkishMessage() {
        var list = Blocklist()
        let result = list.add(input: "123")
        XCTAssertEqual(result, .failure(.invalidNumber(.tooShort)))
        if case .failure(let error) = result { XCTAssertEqual(error.userMessage, PhoneNormalizationError.tooShort.userMessage) }
        XCTAssertTrue(list.entries.isEmpty)
    }

    func testLabelIsTruncated() {
        var list = Blocklist()
        _ = list.add(input: "05551234567", label: String(repeating: "a", count: 200))
        XCTAssertEqual(list.entries[0].label.count, Blocklist.maxLabelLength)
    }

    func testRemove() {
        var list = Blocklist()
        _ = list.add(input: "05551234567")
        list.remove(905551234567)
        XCTAssertTrue(list.entries.isEmpty)
        list.remove(1)   // removing a missing number is harmless
    }

    func testSearch() {
        var list = Blocklist()
        _ = list.add(input: "0555 123 45 67", label: "Çekiliş")
        _ = list.add(input: "0212 999 88 77", label: "Banka sahtesi")
        XCTAssertEqual(list.filtered(by: "").count, 2)
        XCTAssertEqual(list.filtered(by: "0555").map(\.e164), [905551234567])
        XCTAssertEqual(list.filtered(by: "999 88").map(\.e164), [902129998877])
        XCTAssertEqual(list.filtered(by: "CEKILIS").map(\.e164), [905551234567])
        XCTAssertEqual(list.filtered(by: "çekiliş").count, 1)
        XCTAssertTrue(list.filtered(by: "yok").isEmpty)
    }

    func testCallDirectoryTextIsAscendingAndUnique() {
        var list = Blocklist()
        _ = list.add(input: "0555 999 99 99")
        _ = list.add(input: "0212 111 22 33")
        _ = list.add(input: "0555 111 11 11")
        XCTAssertEqual(list.callDirectoryText, "902121112233\n905551111111\n905559999999\n")
        XCTAssertEqual(Blocklist().callDirectoryText, "")
    }

    func testJSONRoundTrip() throws {
        var list = Blocklist()
        _ = list.add(input: "05551234567", label: "x", now: Date(timeIntervalSince1970: 1_700_000_000))
        let decoded = try Blocklist.decode(from: try list.jsonData())
        XCTAssertEqual(decoded, list)
    }

    func testLineReaderWithTinyChunksAndNoTrailingNewline() throws {
        let url = try tempFile("111\n22222\n\n333")
        var lines: [String] = []
        try CallDirectoryFile.forEachLine(at: url, chunkSize: 2) { lines.append($0) }
        XCTAssertEqual(lines, ["111", "22222", "", "333"])
    }

    func testForEachNumberSkipsBadAndOutOfOrderLines() throws {
        let url = try tempFile("905551111111\nabc\n905550000000\n905551111111\n 905552222222 \n\n905553333333\n")
        var numbers: [Int64] = []
        try CallDirectoryFile.forEachNumber(at: url, chunkSize: 5) { numbers.append($0) }
        XCTAssertEqual(numbers, [905551111111, 905552222222, 905553333333])
    }

    func testMissingFileThrows() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("yok-\(UUID().uuidString).txt")
        XCTAssertThrowsError(try CallDirectoryFile.forEachLine(at: url) { _ in })
    }
}
