import XCTest
@testable import SpamCore

final class BuiltInSpamListTests: XCTestCase {
    func testEveryAllowlistEntryParses() {
        for entry in BuiltInSpamList.allowlist {
            XCTAssertNotNil(entry.e164, "\(entry.owner) \(entry.display) numarası çözülemedi")
        }
        XCTAssertEqual(BuiltInSpamList.allowedNumbers.count, BuiltInSpamList.allowlist.count, "izin listesinde tekrar var")
    }

    func testNoRangeTouchesAnAllowedNumber() {
        for range in BuiltInSpamList.strictRanges {
            for allowed in BuiltInSpamList.allowedNumbers {
                XCTAssertFalse(range.contains(allowed), "\(range.label) aralığı izin listesindeki \(allowed) numarasını kapsıyor")
            }
        }
    }

    func testBuiltInNumbersAreValidAndNotAllowed() {
        let all = BuiltInSpamList.basicNumbers + BuiltInSpamList.suspiciousNumbers
        let allowed = BuiltInSpamList.allowedNumbers
        for number in all {
            XCTAssertFalse(allowed.contains(number))
            XCTAssertTrue(number >= 900_000_000_000 && number < 1_000_000_000_000, "\(number) 90 ile başlayan 12 haneli olmalı")
        }
        XCTAssertEqual(Set(all).count, all.count, "hazır listede tekrar var")
    }

    func testRangesDoNotOverlapAndAreWithinLimits() {
        let ranges = BuiltInSpamList.strictRanges.sorted { $0.start < $1.start }
        for (a, b) in zip(ranges, ranges.dropFirst()) {
            XCTAssertLessThan(a.end, b.start, "\(a.label) ile \(b.label) çakışıyor")
        }
        XCTAssertTrue(BuiltInSpamList.strictRanges.allSatisfy { $0.count <= 10_000 })
        XCTAssertLessThan(BuiltInSpamList.count(for: .strict), 100_000)
    }

    func testDefaultsAreBasicOnly() {
        let defaults = ProtectionSettings()
        XCTAssertTrue(defaults.basic)
        XCTAssertFalse(defaults.strict)
        XCTAssertFalse(defaults.suspicious)
    }

    func testBuilderIsAscendingUniqueAndRespectsLevels() {
        let off = ProtectionSettings(basic: false, strict: false, suspicious: false)
        XCTAssertEqual(CallDirectoryBuilder.numbers(user: [], protection: off), [])

        let basic = CallDirectoryBuilder.numbers(user: [], protection: ProtectionSettings())
        XCTAssertEqual(basic, BuiltInSpamList.basicNumbers.sorted())

        let all = ProtectionSettings(basic: true, strict: true, suspicious: true)
        let list = CallDirectoryBuilder.numbers(user: [905551234567, 908509010670], protection: all)
        XCTAssertEqual(list, NumberList.sortedUnique(list))
        XCTAssertTrue(list.contains(905551234567))
        XCTAssertTrue(list.contains(908504840405))   // inside 0850 484 xxxx
        XCTAssertEqual(list.filter { $0 == 908509010670 }.count, 1)
    }

    func testAllowedNumbersAreRemovedFromBuiltInButKeptWhenUserAddsThem() {
        let bankNumber = BuiltInSpamList.allowlist.first!.e164!
        let all = ProtectionSettings(basic: true, strict: true, suspicious: true)
        XCTAssertFalse(CallDirectoryBuilder.numbers(user: [], protection: all).contains(bankNumber))
        XCTAssertTrue(CallDirectoryBuilder.numbers(user: [bankNumber], protection: all).contains(bankNumber))
    }

    func testTextHasOneNumberPerLine() {
        let text = CallDirectoryBuilder.text(user: [905551234567], protection: ProtectionSettings(basic: false, strict: false, suspicious: false))
        XCTAssertEqual(text, "905551234567\n")
        XCTAssertEqual(CallDirectoryBuilder.text(user: [], protection: ProtectionSettings(basic: false, strict: false, suspicious: false)), "")
    }
}
