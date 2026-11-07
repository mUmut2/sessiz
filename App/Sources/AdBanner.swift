import GoogleMobileAds
import SwiftUI
import UIKit

/// Bottom banner slot. Collapses to nothing when ads are off, so screens look the same without ads.
struct AdBannerSlot: View {
    var body: some View {
        if AdsConfig.isEnabled {
            AdBannerView()
                .frame(width: AdBannerView.adSize.size.width, height: AdBannerView.adSize.size.height)
                .frame(maxWidth: .infinity)
                .background(Theme.surface)
                .accessibilityLabel("Reklam")
        }
    }
}

private struct AdBannerView: UIViewRepresentable {
    static var adSize: AdSize {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let width = scene?.screen.bounds.width ?? 375
        return largeAnchoredAdaptiveBanner(width: width)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: Self.adSize)
        banner.adUnitID = AdsConfig.bannerUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
