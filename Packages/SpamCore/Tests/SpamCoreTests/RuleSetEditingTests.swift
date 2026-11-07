import XCTest
@testable import SpamCore

final class RuleSetEditingTests: XCTestCase {
    func testLoadFallsBackToDefaults() {
        XCTAssertEqual(RuleSet.load(from: nil), .defaultSet)
        XCTAssertEqual(RuleSet.load(from: Data("bozuk".utf8)), .defaultSet)
    }

    func testLoadReadsStoredRules() throws {
        var set = RuleSet.defaultSet
        set.setEnabled(false, forRuleID: "default.block.bahis")
        let loaded = RuleSet.load(from: try set.jsonData())
        XCTAssertEqual(loaded, set)
    }

    func testAddUserRule() {
        var set = RuleSet.defaultSet
        let result = set.addUserRule(pattern: "  Süper Fırsat ", target: .body, mode: .contains, action: .block)
        guard case .success(let rule) = result else { return XCTFail("eklenemedi") }
        XCTAssertEqual(rule.pattern, "Süper Fırsat")
        XCTAssertEqual(rule.name, "Süper Fırsat")
        XCTAssertFalse(rule.isDefault)
        XCTAssertEqual(set.userRules, [rule])
        XCTAssertEqual(set.defaultRules.count, DefaultRules.pack.count)
    }

    func testTooShortAndEmptyAreRejected() {
        var set = RuleSet.defaultSet
        XCTAssertEqual(set.addUserRule(pattern: "", target: .body, mode: .contains, action: .block),
                       .failure(.tooShort))
        XCTAssertEqual(set.addUserRule(pattern: " a ", target: .body, mode: .contains, action: .block),
                       .failure(.tooShort))
        XCTAssertTrue(set.userRules.isEmpty)
    }

    func testDuplicateIsRejectedIgnoringCaseAndAccents() {
        var set = RuleSet.defaultSet
        _ = set.addUserRule(pattern: "ÇEKİLİŞ KAZANDIN", target: .body, mode: .contains, action: .block)
        let again = set.addUserRule(pattern: "cekilis kazandin", target: .body, mode: .contains, action: .block)
        XCTAssertEqual(again, .failure(.duplicate))
        // Same text but another action is a different rule.
        let allow = set.addUserRule(pattern: "cekilis kazandin", target: .body, mode: .contains, action: .allow)
        XCTAssertNotNil(try? allow.get())
    }

    func testRemoveOnlyAffectsUserRules() {
        var set = RuleSet.defaultSet
        guard case .success(let rule) = set.addUserRule(pattern: "deneme", target: .sender, mode: .wholeWord, action: .allow)
        else { return XCTFail("eklenemedi") }
        set.removeUserRule(id: "default.block.bahis")
        XCTAssertEqual(set.defaultRules.count, DefaultRules.pack.count)
        set.removeUserRule(id: rule.id)
        XCTAssertTrue(set.userRules.isEmpty)
    }

    func testSetEnabledChangesClassification() {
        var set = RuleSet.defaultSet
        let text = "Bahis sitemize hosgeldiniz"
        XCTAssertTrue(MessageClassifier(rules: set.rules).classify(sender: "Biri", body: text).isSpam)
        set.setEnabled(false, forRuleID: "default.block.bahis")
        XCTAssertFalse(MessageClassifier(rules: set.rules).classify(sender: "Biri", body: text).isSpam)
    }

    func testUserAllowRuleBeatsDefaultBlock() {
        var set = RuleSet.defaultSet
        _ = set.addUserRule(pattern: "Kargo Market", target: .sender, mode: .contains, action: .allow)
        let verdict = MessageClassifier(rules: set.rules).classify(sender: "KARGO MARKET", body: "Bonus puanlariniz hazir")
        XCTAssertFalse(verdict.isSpam)
    }

    func testResetRestoresDefaultsAndDropsUserRules() {
        var set = RuleSet.defaultSet
        _ = set.addUserRule(pattern: "deneme", target: .body, mode: .contains, action: .block)
        set.setEnabled(false, forRuleID: "default.block.casino")
        set.resetToDefaults()
        XCTAssertEqual(set, .defaultSet)
    }

    func testTooLongPatternRejected() {
        var set = RuleSet.defaultSet
        let long = String(repeating: "a", count: RuleSet.maxPatternLength + 1)
        let result = set.addUserRule(pattern: long, target: .body, mode: .contains, action: .block)
        XCTAssertEqual(result.failureValue, .tooLong)
    }

    func testTooManyUserRulesRejected() {
        var set = RuleSet.defaultSet
        for i in 0..<RuleSet.maxUserRules {
            _ = set.addUserRule(pattern: "kelime\(i)", target: .body, mode: .contains, action: .block)
        }
        XCTAssertEqual(set.userRules.count, RuleSet.maxUserRules)
        let result = set.addUserRule(pattern: "fazladan", target: .body, mode: .contains, action: .block)
        XCTAssertEqual(result.failureValue, .tooMany)
    }

    func testOversizedFileFallsBackToDefaults() {
        let big = Data(repeating: 0x20, count: RuleSet.maxFileBytes + 1)
        XCTAssertEqual(RuleSet.load(from: big), .defaultSet)
    }
}

private extension Result {
    var failureValue: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
