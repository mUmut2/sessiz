import XCTest
@testable import SpamCore

final class AppGroupConfigTests: XCTestCase {
    func testMissingKeyReturnsNil() {
        // The test runner's main bundle has no SessizAppGroupID key.
        XCTAssertNil(AppGroupConfig.identifier(in: .main))
    }
}
