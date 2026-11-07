import XCTest
@testable import SpamCore

final class RuleSetTests: XCTestCase {
    func testJSONRoundTrip() throws {
        let original = RuleSet.defaultSet
        let data = try original.jsonData()
        let decoded = try RuleSet.decode(from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.version, RuleSet.currentVersion)
    }

    func testDefaultPackIdsAreUniqueAndMarkedDefault() {
        let ids = DefaultRules.pack.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertTrue(DefaultRules.pack.allSatisfy { $0.isDefault && $0.isEnabled && $0.action == .block })
        XCTAssertFalse(DefaultRules.pack.contains { TurkishText.fold($0.pattern).trimmingCharacters(in: .whitespaces).isEmpty })
    }

    func testUserRuleIsNotDefault() {
        XCTAssertFalse(MessageRule(name: "a", pattern: "b").isDefault)
    }

    func testInvalidJSONThrows() {
        XCTAssertThrowsError(try RuleSet.decode(from: Data("not json".utf8)))
    }
}
