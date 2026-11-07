import XCTest
@testable import SpamCore

final class MessageClassifierTests: XCTestCase {
    private let defaults = MessageClassifier(rules: DefaultRules.pack)

    // MARK: Default pack blocks obvious spam

    func testDefaultPackBlocksSpam() {
        let spam = [
            "Kaçak bahis sitemizde 500 TL bonus sizi bekliyor",
            "TEBRİKLER! ÇEKİLİŞ kazandınız",
            "Hemen tıklayın: bit.ly/abc123",
            "Hemen tiklayiniz",
            "Borcunuz nedeniyle HACİZ işlemi başlatılacaktır",
            "Icra takibi için arayın",
            "Ödülünüz: tinyurl.com/xyz",
            "CASINO FREESPIN fırsatı"
        ]
        for text in spam {
            let verdict = defaults.classify(sender: "05551234567", body: text)
            XCTAssertTrue(verdict.isSpam, "should block: \(text)")
        }
    }

    func testNormalMessagesPass() {
        let ok = [
            "Yarın saat 15'te toplantıya geliyor musun?",
            "Akşam yemeğe gelir misin",
            "Kargonuz yarın teslim edilecek",
            "Alfabetik sıralama listesi",
            ""
        ]
        for text in ok {
            let verdict = defaults.classify(sender: "05551234567", body: text)
            XCTAssertFalse(verdict.isSpam, "should pass: \(text)")
            XCTAssertEqual(verdict.source, .noMatch)
        }
    }

    func testWholeWordDoesNotMatchInsideOtherWord() {
        // "kaçak" and "icra" are whole-word rules; "kaçakçılık"/"icraat" must not match
        XCTAssertFalse(defaults.classify(sender: nil, body: "icraat yapıldı").isSpam)
        XCTAssertFalse(defaults.classify(sender: nil, body: "kaçakçılık haberi").isSpam)
        XCTAssertTrue(defaults.classify(sender: nil, body: "icra dairesi").isSpam)
    }

    // MARK: Safe rules

    func testOneTimeCodesAlwaysPass() {
        let codes = [
            "Doğrulama kodunuz: 482913",
            "e-Devlet giriş kodunuz 123456",
            "Şifreniz 4821. Kimseyle paylaşmayın.",
            "Your verification code is 998877",
            "OTP: 556677",
            "Tek kullanımlık şifreniz: 1234",
            "3D Secure şifreniz 123 456",
            "Kodunuz 7788"
        ]
        for text in codes {
            let verdict = defaults.classify(sender: "BILINMEYEN", body: text)
            XCTAssertFalse(verdict.isSpam, "should pass: \(text)")
            XCTAssertEqual(verdict.source, .oneTimeCode, text)
        }
    }

    func testOneTimeCodeBeatsBlockKeyword() {
        let verdict = defaults.classify(sender: "X", body: "Bonus hesabınız için doğrulama kodu: 123456")
        XCTAssertEqual(verdict.action, .allow)
        XCTAssertEqual(verdict.source, .oneTimeCode)
    }

    func testCodeWordWithoutDigitsIsNotACode() {
        let verdict = defaults.classify(sender: "X", body: "Doğrulama kodu için bonus bahis")
        XCTAssertTrue(verdict.isSpam)
    }

    func testGenericCodeWithLinkIsNotTrusted() {
        let verdict = defaults.classify(sender: "X", body: "Kodunuz 1234 tıklayın bit.ly/abc")
        XCTAssertTrue(verdict.isSpam)
    }

    func testTrustedSendersPassEvenWithBlockKeywords() {
        let senders = ["AKBANK", "Akbank", "E-DEVLET", "e-Devlet", "edevlet", "TÜRK TELEKOM", "Garanti BBVA", "İŞ BANKASI"]
        for sender in senders {
            let verdict = defaults.classify(sender: sender, body: "Bonus puanınız 100 TL, tıklayın")
            XCTAssertFalse(verdict.isSpam, sender)
            if case .trustedSender = verdict.source {} else { XCTFail("source for \(sender)") }
        }
    }

    func testTrustedSenderMustBeExactName() {
        XCTAssertFalse(defaults.classify(sender: "AKBANKK", body: "bahis").action == .allow)
        XCTAssertTrue(defaults.classify(sender: "FAKEAKBANK", body: "bahis").isSpam)
    }

    // MARK: User rules

    func testUserBlockRuleOnSender() {
        let rule = MessageRule(name: "Reklamcı", pattern: "SUPERMARKET", target: .sender, mode: .exact, action: .block)
        let classifier = MessageClassifier(rules: [rule])
        XCTAssertTrue(classifier.classify(sender: "Supermarket", body: "indirim").isSpam)
        XCTAssertFalse(classifier.classify(sender: "Supermarket 2", body: "indirim").isSpam)
        XCTAssertFalse(classifier.classify(sender: nil, body: "indirim").isSpam)
    }

    func testUserAllowRuleBeatsBlockRule() {
        let block = MessageRule(name: "bahis", pattern: "bahis")
        let allow = MessageRule(name: "Kuzenim", pattern: "bahis sitesi haberi", action: .allow)
        let classifier = MessageClassifier(rules: [block, allow])
        let verdict = classifier.classify(sender: nil, body: "Bu bahis sitesi haberi doğru mu?")
        XCTAssertEqual(verdict.action, .allow)
        XCTAssertEqual(verdict.source, .rule(allow))
        XCTAssertTrue(classifier.classify(sender: nil, body: "bahis oyna").isSpam)
    }

    func testDisabledAndEmptyRulesAreIgnored() {
        let off = MessageRule(name: "x", pattern: "merhaba", isEnabled: false)
        let empty = MessageRule(name: "y", pattern: "   ")
        let classifier = MessageClassifier(rules: [off, empty])
        XCTAssertFalse(classifier.classify(sender: nil, body: "merhaba dünya").isSpam)
    }

    func testPrefixMode() {
        let rule = MessageRule(name: "p", pattern: "SONUC:", mode: .prefix)
        let classifier = MessageClassifier(rules: [rule])
        XCTAssertTrue(classifier.classify(sender: nil, body: "Sonuç: kazandın").isSpam)
        XCTAssertFalse(classifier.classify(sender: nil, body: "Bugünkü sonuç: kazandın").isSpam)
    }

    func testMatchingIsTurkishInsensitive() {
        let rule = MessageRule(name: "Çekiliş", pattern: "ÇEKİLİŞ")
        let classifier = MessageClassifier(rules: [rule])
        XCTAssertTrue(classifier.classify(sender: nil, body: "cekilis sonucu").isSpam)
        XCTAssertTrue(classifier.classify(sender: nil, body: "çekiliş sonucu").isSpam)
        XCTAssertTrue(classifier.classify(sender: nil, body: "ÇEKİLİŞ SONUCU").isSpam)
        XCTAssertTrue(classifier.classify(sender: nil, body: "CEKILIS SONUCU").isSpam)
    }

    func testExplanationsAreFilled() {
        let verdicts = [
            defaults.classify(sender: nil, body: "bahis"),
            defaults.classify(sender: nil, body: "doğrulama kodu 123456"),
            defaults.classify(sender: "AKBANK", body: "merhaba"),
            defaults.classify(sender: nil, body: "merhaba")
        ]
        for v in verdicts { XCTAssertFalse(v.explanation.isEmpty) }
        XCTAssertTrue(verdicts[0].explanation.contains("Engelleme kuralı"))
    }

    // MARK: Safe code digits

    func testHasCodeDigits() {
        XCTAssertTrue(SafeRules.hasCodeDigits("kod 1234"))
        XCTAssertTrue(SafeRules.hasCodeDigits("kod 12345678"))
        XCTAssertTrue(SafeRules.hasCodeDigits("kod 123-456"))
        XCTAssertTrue(SafeRules.hasCodeDigits("kod 123 456"))
        XCTAssertFalse(SafeRules.hasCodeDigits("kod 123"))
        XCTAssertFalse(SafeRules.hasCodeDigits("kod 123456789"))
        XCTAssertFalse(SafeRules.hasCodeDigits("kod 12 34"))
        XCTAssertFalse(SafeRules.hasCodeDigits("kod"))
    }
}
