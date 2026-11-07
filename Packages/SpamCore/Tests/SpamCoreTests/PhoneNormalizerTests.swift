import XCTest
@testable import SpamCore

final class PhoneNormalizerTests: XCTestCase {
    private func value(_ input: String, file: StaticString = #filePath, line: UInt = #line) -> Int64? {
        switch PhoneNormalizer.normalize(input) {
        case .success(let number): return number
        case .failure: return nil
        }
    }

    private func error(_ input: String) -> PhoneNormalizationError? {
        if case .failure(let e) = PhoneNormalizer.normalize(input) { return e }
        return nil
    }

    func testMobileFormatsAllGiveSameNumber() {
        let inputs = [
            "0555 123 45 67", "05551234567", "+90 555 123 45 67", "+905551234567", "905551234567",
            "5551234567", "(0555) 123-45-67", "0 555 123 45 67", "00905551234567", "0555.123.45.67",
            "  0555 123 45 67  ", "+90 (555) 123 45 67", "0555\u{00A0}123\u{00A0}45\u{00A0}67"
        ]
        for input in inputs {
            XCTAssertEqual(value(input), 905551234567, "input: \(input)")
        }
    }

    func testLandlineAndServiceNumbers() {
        XCTAssertEqual(value("0212 123 45 67"), 902121234567)
        XCTAssertEqual(value("0850 123 45 67"), 908501234567)
        XCTAssertEqual(value("0800 123 45 67"), 908001234567)
        XCTAssertEqual(value("+90 312 123 45 67"), 903121234567)
    }

    func testForeignNumbers() {
        XCTAssertEqual(value("+1 202 555 0123"), 12025550123)
        XCTAssertEqual(value("+44 20 7946 0958"), 442079460958)
        XCTAssertEqual(value("0044 20 7946 0958"), 442079460958)
    }

    func testErrors() {
        XCTAssertEqual(error(""), .empty)
        XCTAssertEqual(error("   "), .empty)
        XCTAssertEqual(error("---"), .empty)
        XCTAssertEqual(error("abc"), .invalidCharacters)
        XCTAssertEqual(error("0555 123 45 6a"), .invalidCharacters)
        XCTAssertEqual(error("0555+1234567"), .invalidCharacters)
        XCTAssertEqual(error("112"), .tooShort)
        XCTAssertEqual(error("0555 123 45"), .tooShort)
        XCTAssertEqual(error("0555 123 45 678"), .tooLong)
        XCTAssertEqual(error("+90 555 123 45 678"), .tooLong)
        XCTAssertEqual(error("0155 123 45 67"), .invalidFormat)   // area code cannot start with 1
        XCTAssertEqual(error("0444 123 4"), .shortNumberUnsupported)
        XCTAssertEqual(error("444 1234"), .shortNumberUnsupported)
        XCTAssertEqual(error("+0 555"), .invalidFormat)
        XCTAssertEqual(error("+1234"), .tooShort)
        XCTAssertEqual(error("+1234567890123456"), .tooLong)
    }

    func testEveryErrorHasTurkishMessage() {
        let all: [PhoneNormalizationError] = [.empty, .invalidCharacters, .tooShort, .tooLong, .invalidFormat, .shortNumberUnsupported]
        for item in all { XCTAssertFalse(item.userMessage.isEmpty) }
    }

    func testDisplayFormat() {
        XCTAssertEqual(PhoneFormatter.display(905551234567), "+90 555 123 45 67")
        XCTAssertEqual(PhoneFormatter.display(908501234567), "+90 850 123 45 67")
        XCTAssertEqual(PhoneFormatter.display(12025550123), "+12025550123")
    }

    func testSortedUnique() {
        XCTAssertEqual(NumberList.sortedUnique([905559999999, 905551111111, 905559999999, 902121234567]),
                       [902121234567, 905551111111, 905559999999])
        XCTAssertEqual(NumberList.sortedUnique([]), [])
    }
}
