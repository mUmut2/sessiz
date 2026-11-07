import Foundation
import GoogleMobileAds

/// In-app ads (Google AdMob). Everything is configured in project.yml `settings.base`
/// (ADS_ENABLED, ADMOB_APP_ID, ADMOB_BANNER_UNIT_ID) and read here from Info.plist.
///
/// Rules:
///  - banner only at the bottom of the Numaralar and Mesajlar tabs
///  - never on Durum (setup), Ayarlar, sheets or the Test et screen
///  - the extensions never load the ads SDK
///  - no tracking prompt: without it iOS gives no advertising identifier, so ads are not personalised
enum AdsConfig {
    private static func infoString(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    static let isEnabled: Bool = infoString("SessizAdsEnabled") == "YES" && !bannerUnitID.isEmpty

    static let bannerUnitID: String = infoString("SessizAdBannerUnitID")

    /// Google's published sample ids start with this publisher number. A build that still uses them shows "Test Ad"
    /// banners: fine for TestFlight, never for the App Store.
    static var usesTestIDs: Bool { bannerUnitID.hasPrefix("ca-app-pub-3940256099942544") }

    /// Call once at launch. Does nothing when ads are switched off.
    static func startIfEnabled() {
        guard isEnabled else { return }
        MobileAds.shared.start()
    }
}
