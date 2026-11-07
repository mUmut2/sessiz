import XCTest
@testable import SpamCore

final class TurkishTextTests: XCTestCase {
    func testFoldsTurkishLetters() {
        XCTAssertEqual(TurkishText.fold("ÇEKİLİŞ"), "cekilis")
        XCTAssertEqual(TurkishText.fold("çekiliş"), "cekilis")
        XCTAssertEqual(TurkishText.fold("KAZANDINIZ"), "kazandiniz")
        XCTAssertEqual(TurkishText.fold("kazandınız"), "kazandiniz")
        XCTAssertEqual(TurkishText.fold("Tıklayın"), "tiklayin")
        XCTAssertEqual(TurkishText.fold("ĞÜŞÖÇİI"), "gusocii")
        XCTAssertEqual(TurkishText.fold("ğüşöçiı"), "gusocii")
        XCTAssertEqual(TurkishText.fold("Hello WORLD 123"), "hello world 123")
    }

    func testDecomposedDottedCapitalI() {
        // "İ" written as I + combining dot above
        XCTAssertEqual(TurkishText.fold("I\u{0307}stanbul"), "istanbul")
        // "ş" written as s + combining cedilla
        XCTAssertEqual(TurkishText.fold("s\u{0327}ans"), "sans")
    }

    func testKeyIgnoresPunctuation() {
        XCTAssertEqual(TurkishText.key(of: "E-Devlet"), "edevlet")
        XCTAssertEqual(TurkishText.key(of: "Türk Telekom"), "turktelekom")
    }

    func testTokens() {
        XCTAssertEqual(TurkishText.tokens(ofFolded: "bit.ly/abc, merhaba!"), ["bit", "ly", "abc", "merhaba"])
        XCTAssertEqual(TurkishText.tokens(ofFolded: "  "), [])
    }

    func testContainsSequence() {
        let tokens = ["dogrulama", "kodunuz", "123456"]
        XCTAssertTrue(TurkishText.containsSequence(tokens, ["dogrulama", "kodunuz"]))
        XCTAssertFalse(TurkishText.containsSequence(tokens, ["dogrulama", "kod"]))
        XCTAssertTrue(TurkishText.containsSequence(tokens, ["dogrulama", "kod"], prefixLast: true))
        XCTAssertFalse(TurkishText.containsSequence(tokens, []))
        XCTAssertFalse(TurkishText.containsSequence([], ["a"]))
    }
}
