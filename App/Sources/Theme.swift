import SwiftUI
import UIKit

/// Design tokens. One accent colour, no gradients, no blur, one corner radius, 8pt grid.
///
/// Palette
///   navy  #03045E   light  #CAF0F8   cyan  #00B4D8   white  #FFFFFF
///   dark-mode background = navy * 0.55 = #020234 (about 45% darker)
///
/// WCAG contrast ratios (computed with the WCAG 2.x relative-luminance formula; AA needs 4.5:1 for text, 3:1 for large text / UI):
///   navy  on light      14.65   text on background (light mode)
///   navy  on white      17.75   text on cards (light mode)
///   light on navy       14.65   text on surfaces (dark mode), light text on primary button
///   light on #020234    16.34   text on background (dark mode)
///   navy  on cyan        7.20   any text placed on the accent colour
///   cyan  on navy        7.20   accent on dark surfaces
///   cyan  on #020234     8.03   accent on dark background
///   secondary text = main text at 70% opacity:
///     navy@70 on light 6.67, navy@70 on white 7.39, light@70 on navy 7.34, light@70 on #020234 8.07
///   cyan  on light       2.03   FAILS even 3:1 -> never used for text or icons on light backgrounds
///   cyan  on white       2.46   FAILS 3:1 -> same rule. Toggles still use cyan (iOS draws a white thumb and an off state),
///                               which is below the 3:1 guideline for the track; accepted because the on/off label is also in text.
/// Therefore in light mode "selected" items use navy; in dark mode they use cyan.
enum Theme {
    // MARK: Layout
    static let cornerRadius: CGFloat = 8

    enum Spacing {
        static let xs: CGFloat = 8
        static let s: CGFloat = 16
        static let m: CGFloat = 24
        static let l: CGFloat = 32
    }

    // MARK: Raw colours
    private static let navy = UIColor(hex: 0x03045E)
    private static let cyan = UIColor(hex: 0x00B4D8)
    private static let light = UIColor(hex: 0xCAF0F8)
    private static let white = UIColor(hex: 0xFFFFFF)
    private static let darkBackground = UIColor(hex: 0x020234)

    private static func dynamic(light lightColor: UIColor, dark darkColor: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    // MARK: Semantic colours
    static let background = dynamic(light: light, dark: darkBackground)
    static let surface = dynamic(light: white, dark: navy)
    static let text = dynamic(light: navy, dark: light)
    static let secondaryText = text.opacity(0.7)
    /// Accent for toggles and filled shapes. Never used for small text on light backgrounds.
    static let accent = Color(uiColor: cyan)
    /// Text or icon placed on top of `accent`.
    static let onAccent = Color(uiColor: navy)
    /// Selected tab / selected state: navy on light mode (cyan fails contrast there), cyan on dark mode.
    static let selection = dynamic(light: navy, dark: cyan)
    /// Primary button: navy fill with light text; in dark mode navy is the surface, so use cyan fill with navy text.
    static let primaryFill = dynamic(light: navy, dark: cyan)
    static let primaryText = dynamic(light: light, dark: navy)
    /// Destructive actions use only the system red.
    static let destructive = Color(uiColor: .systemRed)
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

// MARK: - Button styles (one primary action per screen)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.primaryText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Theme.primaryFill, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.text.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
